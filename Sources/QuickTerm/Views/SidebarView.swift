import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: BookmarkStore
    let onRunBookmark: (CommandBookmark) -> Void
    let onAddTapped: () -> Void
    let onEditTapped: (CommandBookmark) -> Void

    @State private var bookmarkToDelete: CommandBookmark?
    @State private var searchText: String = ""

    private var filteredBookmarks: [CommandBookmark] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.bookmarks }
        return store.bookmarks.filter {
            $0.name.lowercased().contains(q) ||
            $0.command.lowercased().contains(q) ||
            $0.directory.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Komutlar")
                    .font(.headline)
                Spacer()
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Yeni komut ekle")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if store.bookmarks.count > 4 {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    TextField("Ara...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(6)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }

            Divider()

            if filteredBookmarks.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "terminal")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text(store.bookmarks.isEmpty ? "Henüz kayıtlı komut yok" : "Eşleşen komut yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if store.bookmarks.isEmpty {
                        Button("Komut Ekle") {
                            onAddTapped()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                List {
                    ForEach(filteredBookmarks) { bookmark in
                        BookmarkRow(
                            bookmark: bookmark,
                            onRun: { onRunBookmark(bookmark) },
                            onEdit: { onEditTapped(bookmark) },
                            onDelete: { bookmarkToDelete = bookmark }
                        )
                        .listRowInsets(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6))
                        .listRowSeparator(.hidden)
                    }
                    .onMove { source, destination in
                        if searchText.isEmpty {
                            store.move(from: source, to: destination)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .alert(
            "Komutu Sil",
            isPresented: Binding(
                get: { bookmarkToDelete != nil },
                set: { if !$0 { bookmarkToDelete = nil } }
            ),
            presenting: bookmarkToDelete
        ) { bookmark in
            Button("İptal", role: .cancel) {
                bookmarkToDelete = nil
            }
            Button("Sil", role: .destructive) {
                store.delete(bookmark)
                bookmarkToDelete = nil
            }
        } message: { bookmark in
            Text("\"\(bookmark.name)\" komutunu silmek istediğine emin misin?")
        }
    }
}

private struct BookmarkRow: View {
    let bookmark: CommandBookmark
    let onRun: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    private var folderName: String? {
        guard !bookmark.directory.isEmpty else { return nil }
        return URL(fileURLWithPath: bookmark.directory).lastPathComponent
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(bookmark.command)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let folderName, !folderName.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                            .font(.system(size: 9))
                        Text(folderName)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if isHovering {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Düzenle")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.borderless)
                    .help("Sil")
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.primary.opacity(0.07) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onRun()
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("Çalıştır") { onRun() }
            Divider()
            Button("Düzenle") { onEdit() }
            Button("Sil", role: .destructive) { onDelete() }
        }
    }
}
