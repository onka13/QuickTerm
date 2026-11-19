import SwiftUI
import AppKit

struct BookmarkEditorSheet: View {
    enum Mode {
        case add(defaultDirectory: String)
        case edit(CommandBookmark)

        var title: String {
            switch self {
            case .add: return "New Command"
            case .edit: return "Edit Command"
            }
        }

        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }
    }

    let mode: Mode
    let onSave: (_ name: String, _ directory: String, _ command: String) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var directory: String = ""
    @State private var command: String = ""
    @State private var showDeleteConfirmation = false

    init(
        mode: Mode,
        onSave: @escaping (_ name: String, _ directory: String, _ command: String) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onSave = onSave
        self.onDelete = onDelete

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
                Text("Name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("e.g. Start Backend", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Directory (Optional)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("/Users/...", text: $directory)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button("Choose...") {
                        pickDirectory()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Command")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("e.g. npm run dev", text: $command)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            HStack {
                if mode.isEditing, onDelete != nil {
                    Button("Delete", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
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
        .alert("Delete Command", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(name)\"?")
        }
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
