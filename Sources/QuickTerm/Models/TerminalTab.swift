import Foundation
import AppKit
import SwiftTerm

@MainActor
final class TerminalTab: Identifiable, ObservableObject {
    let id = UUID()
    @Published var title: String
    @Published var currentDirectory: String

    let terminalView: LocalProcessTerminalView
    private var delegateAdapter: TabProcessDelegate?
    var onProcessTerminated: (() -> Void)?

    init(initialDirectory: String) {
        let dir = FileManager.default.fileExists(atPath: initialDirectory)
            ? initialDirectory
            : FileManager.default.homeDirectoryForCurrentUser.path
        self.currentDirectory = dir
        self.title = URL(fileURLWithPath: dir).lastPathComponent.isEmpty ? "zsh" : URL(fileURLWithPath: dir).lastPathComponent

        let tv = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 500))
        tv.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.nativeBackgroundColor = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        tv.nativeForegroundColor = NSColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1.0)
        tv.setCursorStyle(.blinkUnderline)
        self.terminalView = tv

        let adapter = TabProcessDelegate(tab: self)
        self.delegateAdapter = adapter
        tv.processDelegate = adapter

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let execName = "-" + URL(fileURLWithPath: shell).lastPathComponent
        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
        env.append("LANG=en_US.UTF-8")

        tv.startProcess(
            executable: shell,
            args: [],
            environment: env,
            execName: execName,
            currentDirectory: dir
        )
    }

    /// Returns the live working directory of the shell process if available, falling back to cached directory.
    func resolvedCurrentDirectory() -> String {
        let pid = terminalView.process.shellPid
        if let liveDir = ProcessDirectoryHelper.workingDirectory(for: pid) {
            currentDirectory = liveDir
            return liveDir
        }
        return currentDirectory
    }

    func sendCommand(_ command: String, directory: String?) {
        let trimmedDir = directory?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let liveDir = resolvedCurrentDirectory()

        let payload: String
        if !trimmedDir.isEmpty && trimmedDir != liveDir {
            let escaped = trimmedDir.replacingOccurrences(of: "'", with: "'\\''")
            payload = "cd '\(escaped)' && \(command)\n"
        } else {
            payload = "\(command)\n"
        }

        terminalView.send(txt: payload)
        focus()
    }

    func focus() {
        terminalView.window?.makeFirstResponder(terminalView)
    }

    func adjustFontSize(delta: CGFloat) {
        let currentSize = terminalView.font.pointSize
        let nextSize = min(max(currentSize + delta, 10), 28)
        terminalView.font = NSFont.monospacedSystemFont(ofSize: nextSize, weight: .regular)
    }
}

@MainActor
private final class TabProcessDelegate: NSObject, LocalProcessTerminalViewDelegate {
    weak var tab: TerminalTab?

    init(tab: TerminalTab) {
        self.tab = tab
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tab?.title = trimmed
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let directory, !directory.isEmpty else { return }
        let resolvedPath: String
        if let url = URL(string: directory), url.isFileURL {
            resolvedPath = url.path
        } else {
            resolvedPath = directory
        }
        tab?.currentDirectory = resolvedPath
        let folder = URL(fileURLWithPath: resolvedPath).lastPathComponent
        if !folder.isEmpty {
            tab?.title = folder
        }
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        tab?.onProcessTerminated?()
    }

    func processFailedToStart(source: TerminalView, error: LocalProcessError) {}

    func programStatusChanged(source: TerminalView, records: [TerminalProgramStatus]) {}
}

@MainActor
final class TerminalWorkspace: ObservableObject {
    @Published var tabs: [TerminalTab] = []
    @Published var selectedTabID: UUID?

    var activeTab: TerminalTab? {
        tabs.first { $0.id == selectedTabID } ?? tabs.first
    }

    init() {
        addTab(in: FileManager.default.homeDirectoryForCurrentUser.path)
    }

    func addTab(in directory: String? = nil) {
        let dir = directory ?? activeTab?.resolvedCurrentDirectory() ?? FileManager.default.homeDirectoryForCurrentUser.path
        let tab = TerminalTab(initialDirectory: dir)
        tab.onProcessTerminated = { [weak self, weak tab] in
            guard let self, let tab else { return }
            self.closeTab(tab.id)
        }
        tabs.append(tab)
        selectedTabID = tab.id
        DispatchQueue.main.async {
            tab.focus()
        }
    }

    func closeTab(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)

        if tabs.isEmpty {
            addTab(in: FileManager.default.homeDirectoryForCurrentUser.path)
            return
        }

        if selectedTabID == id {
            let nextIndex = min(index, tabs.count - 1)
            selectedTabID = tabs[nextIndex].id
            DispatchQueue.main.async {
                self.activeTab?.focus()
            }
        }
    }

    func selectTab(_ id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        selectedTabID = id
        DispatchQueue.main.async {
            self.activeTab?.focus()
        }
    }

    func runBookmark(_ bookmark: CommandBookmark) {
        if activeTab == nil {
            addTab(in: bookmark.directory.isEmpty ? nil : bookmark.directory)
        }
        activeTab?.sendCommand(bookmark.command, directory: bookmark.directory)
    }
}
