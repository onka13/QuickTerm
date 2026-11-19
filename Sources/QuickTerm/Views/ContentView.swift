import SwiftUI

private enum ActiveEditorSheet: Identifiable {
    case add(defaultDirectory: String)
    case edit(CommandBookmark)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let b): return "edit-\(b.id.uuidString)"
        }
    }
}

struct ContentView: View {
    @ObservedObject var workspace: TerminalWorkspace
    @ObservedObject var bookmarkStore: BookmarkStore
    @Binding var showSidebar: Bool

    @State private var editorSheet: ActiveEditorSheet?

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(
                workspace: workspace,
                showSidebar: $showSidebar
            )

            Divider()

            HSplitView {
                if showSidebar {
                    SidebarView(
                        store: bookmarkStore,
                        onRunBookmark: { bookmark in
                            workspace.runBookmark(bookmark)
                        },
                        onAddTapped: {
                            let dir = workspace.activeTab?.resolvedCurrentDirectory()
                                ?? FileManager.default.homeDirectoryForCurrentUser.path
                            editorSheet = .add(defaultDirectory: dir)
                        },
                        onEditTapped: { bookmark in
                            editorSheet = .edit(bookmark)
                        }
                    )
                    .frame(minWidth: 200, idealWidth: 240, maxWidth: 360)
                }

                TerminalHostView(
                    tabs: workspace.tabs,
                    selectedTabID: workspace.selectedTabID
                )
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 720, minHeight: 460)
        .sheet(item: $editorSheet) { sheet in
            switch sheet {
            case .add(let defaultDirectory):
                BookmarkEditorSheet(mode: .add(defaultDirectory: defaultDirectory)) { name, dir, cmd in
                    bookmarkStore.add(name: name, directory: dir, command: cmd)
                }
            case .edit(let bookmark):
                BookmarkEditorSheet(mode: .edit(bookmark)) { name, dir, cmd in
                    var updated = bookmark
                    updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.directory = dir.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.command = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
                    bookmarkStore.update(updated)
                }
            }
        }
    }
}

private struct TabBarView: View {
    @ObservedObject var workspace: TerminalWorkspace
    @Binding var showSidebar: Bool

    var body: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showSidebar.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 13))
                    .foregroundStyle(showSidebar ? .primary : .secondary)
            }
            .buttonStyle(.borderless)
            .padding(.leading, 10)
            .help("Komut menüsünü gizle/göster (⌘B)")

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(workspace.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isSelected: tab.id == workspace.selectedTabID,
                            onSelect: { workspace.selectTab(tab.id) },
                            onClose: { workspace.closeTab(tab.id) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Button {
                workspace.addTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 8)
            .help("Yeni sekme (⌘T)")
        }
        .frame(height: 36)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct TabItemView: View {
    @ObservedObject var tab: TerminalTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? .primary : .secondary)

            Text(tab.title)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .lineLimit(1)

            if isSelected || isHovering {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.primary.opacity(0.12) : (isHovering ? Color.primary.opacity(0.06) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
