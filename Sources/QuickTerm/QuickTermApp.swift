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
                Button("Yeni Sekme") {
                    workspace.addTab()
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Sekmeyi Kapat") {
                    if let id = workspace.selectedTabID {
                        workspace.closeTab(id)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandMenu("Görünüm") {
                Button(showSidebar ? "Komut Menüsünü Gizle" : "Komut Menüsünü Göster") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSidebar.toggle()
                    }
                }
                .keyboardShortcut("b", modifiers: .command)

                Divider()

                Button("Yazı Boyutunu Büyüt") {
                    workspace.activeTab?.adjustFontSize(delta: 1)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Yazı Boyutunu Küçült") {
                    workspace.activeTab?.adjustFontSize(delta: -1)
                }
                .keyboardShortcut("-", modifiers: .command)
            }
        }
    }
}
