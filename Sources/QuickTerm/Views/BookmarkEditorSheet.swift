import SwiftUI
import AppKit

struct BookmarkEditorSheet: View {
    enum Mode {
        case add(defaultDirectory: String)
        case edit(CommandBookmark)

        var title: String {
            switch self {
            case .add: return "Yeni Komut Ekle"
            case .edit: return "Komutu Düzenle"
            }
        }
    }

    let mode: Mode
    let onSave: (_ name: String, _ directory: String, _ command: String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var directory: String = ""
    @State private var command: String = ""

    init(mode: Mode, onSave: @escaping (_ name: String, _ directory: String, _ command: String) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .add(let defaultDirectory):
            _name = State(initialValue: "")
            _directory = State(initialValue: defaultDirectory)
            _command = State(initialValue: "")
        case .edit(let bookmark):
            _name = State(initialValue: bookmark.name)
            _directory = State(initialValue: bookmark.directory)
            _command = State(initialValue: bookmark.command)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(mode.title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("İsim")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Örn: Backend Başlat", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Klasör (Opsiyonel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("/Users/...", text: $directory)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button("Seç...") {
                        pickDirectory()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Komut")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Örn: npm run dev", text: $command)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            HStack {
                Spacer()
                Button("İptal") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Kaydet") {
                    onSave(name, directory, command)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 440)
    }

    private func pickDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if !directory.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: directory)
        }
        if panel.runModal() == .OK, let url = panel.url {
            directory = url.path
        }
    }
}
