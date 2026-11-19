import SwiftUI
import AppKit

@main
struct QuickTermApp: App {
    @StateObject private var workspace = TerminalWorkspace()
    @StateObject private var bookmarkStore = BookmarkStore()
    @State private var showSidebar = true

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("QuickTerm") {
            ContentView(
                workspace: workspace,
                bookmarkStore: bookmarkStore,
                showSidebar: $showSidebar
            )
            .onAppear {
                DispatchQueue.main.async {
                    workspace.activeTab?.focus()
                }
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    workspace.addTab()
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Close Tab") {
                    if let id = workspace.selectedTabID {
                        workspace.closeTab(id)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandMenu("View") {
                Button(showSidebar ? "Hide Sidebar" : "Show Sidebar") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSidebar.toggle()
                    }
                }
                .keyboardShortcut("b", modifiers: .command)

                Divider()

                Button("Increase Font Size") {
                    workspace.activeTab?.adjustFontSize(delta: 1)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Decrease Font Size") {
                    workspace.activeTab?.adjustFontSize(delta: -1)
                }
                .keyboardShortcut("-", modifiers: .command)
            }
        }
    }
}
