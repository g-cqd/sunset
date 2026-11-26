import AppKit
import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI
import UniformTypeIdentifiers

/// Attachments section inside `PasswordEntryPage` (roadmap 0092 C): lists sealed file attachments on an entry, allows
/// exporting/saving a copy to disk in read mode, and attaching/removing files (up to `VaultAttachment.maxBytes`) in
/// edit mode.
struct PasswordAttachmentsSection: View {
    let attachments: [VaultAttachment]
    let editing: Bool
    let add: (VaultAttachment) -> Bool
    let remove: (UUID) -> Void

    var body: some View {
        if editing || !attachments.isEmpty {
            Section("Attachments") {
                ForEach(attachments) { item in
                    attachmentRow(item)
                }
                if editing {
                    Button {
                        pickFile()
                    } label: {
                        Label("Attach File\u{2026}", systemImage: "paperclip")
                    }
                    .buttonStyle(.quiet)
                }
            }
        }
    }

    private func attachmentRow(_ item: VaultAttachment) -> some View {
        HStack(spacing: Design.Space.s) {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.filename)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(ByteCountFormatter.string(fromByteCount: Int64(item.data.count), countStyle: .file))
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            RowGlyphButton(symbol: "square.and.arrow.down", help: "Save Copy\u{2026}") {
                export(item)
            }
            if editing {
                RowGlyphButton(symbol: "trash", help: "Remove Attachment") {
                    remove(item.id)
                }
            }
        }
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Files up to 4 MB are sealed inside this vault entry."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url) else {
            Feedback.give(.blocked("Could not read \(url.lastPathComponent)"))
            return
        }
        guard data.count <= VaultAttachment.maxBytes else {
            Feedback.give(.blocked("Attachment exceeds the 4 MB limit"))
            return
        }
        let type = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        let attachment = VaultAttachment(
            filename: url.lastPathComponent,
            contentType: type,
            data: data,
            addedAt: Runtime.live.now()
        )
        if !add(attachment) {
            Feedback.give(.blocked("Could not attach \(url.lastPathComponent)"))
        }
    }

    private func export(_ item: VaultAttachment) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = item.filename
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try item.data.write(to: url, options: .atomic)
            Feedback.give(.done("Saved \(item.filename)"))
        } catch {
            Feedback.give(.blocked("Could not save \(item.filename)"))
        }
    }
}
