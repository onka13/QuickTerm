import Foundation

/// A saved terminal command bookmark with an optional working directory.
struct CommandBookmark: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var directory: String
    var command: String

    init(id: UUID = UUID(), name: String, directory: String, command: String) {
        self.id = id
        self.name = name
        self.directory = directory
        self.command = command
    }
}

/// Persists command bookmarks in Application Support as JSON.
@MainActor
final class BookmarkStore: ObservableObject {
    @Published var bookmarks: [CommandBookmark] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("QuickTerm", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("bookmarks.json")
        load()
    }

    func add(name: String, directory: String, command: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCmd = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDir = directory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedCmd.isEmpty else { return }

        let item = CommandBookmark(name: trimmedName, directory: trimmedDir, command: trimmedCmd)
        bookmarks.append(item)
        save()
    }

    func update(_ bookmark: CommandBookmark) {
        guard let idx = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return }
        bookmarks[idx] = bookmark
        save()
    }

    func delete(_ bookmark: CommandBookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        bookmarks.move(fromOffsets: source, toOffset: destination)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([CommandBookmark].self, from: data) else {
            return
        }
        bookmarks = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
