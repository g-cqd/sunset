internal import MarkdownLookKit
internal import SunsetDocuments
internal import SunsetShell
internal import SwiftUI

/// A block changed here and on disk, on the block itself (roadmap 0023 step M-e, the owner's choice of 2026-11-16): what
/// the disk says, tinted, and the three answers. On the page what is here is drawn above it, tinted too; in the source the
/// text view tints it where it stands, and this card sits under it.
struct ConflictCard: View {
    let content: DocumentContent
    let conflict: DocumentConflict
    /// What is here, to draw above the disk's (the page); nil in the source, where the text itself shows it.
    var mine: String?

    private var kind: DocumentKind {
        content.document.kind
    }
    private var settings: ViewerSettings {
        content.document.source.settings
    }
    private var isCurrent: Bool {
        content.document.conflicts.count > 1 && content.shownConflict == conflict.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let mine {
                side("Mine", mine, removed: "Removed here", tint: ConflictTint.mineColor)
            }
            side("On disk", conflict.theirs, removed: "Removed on disk", tint: ConflictTint.theirsColor)
            HStack(spacing: Design.Space.m) {
                Button("Keep Mine") { content.answer(conflict.id, keeping: .mine) }
                Button("Keep Disk\u{2019}s") { content.answer(conflict.id, keeping: .theirs) }
                Button("Keep Both") { content.answer(conflict.id, keeping: .both) }
                    .disabled(conflict.theirs.isEmpty || conflict.range.isEmpty)
                Spacer(minLength: 0)
            }
            .controlSize(.small)
            .padding(.horizontal, Design.Space.l)
            .padding(.vertical, Design.Space.s)
        }
        .background(.quaternary.opacity(0.35))
        .overlay(alignment: .leading) {
            Rectangle().fill(isCurrent ? Color.accentColor : Color.secondary.opacity(0.5)).frame(width: 3)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Conflict with the file on disk")
    }

    @ViewBuilder
    private func side(_ label: String, _ text: String, removed: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            Text(text.isEmpty ? removed : label)
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Design.Space.l)
            if !text.isEmpty {
                if mine == nil {
                    Text(text.trimmingCharacters(in: .newlines))
                        .font(.system(size: content.fontSize, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Design.Space.l)
                } else {
                    PagePartView(text: text, kind: kind, settings: settings).equatable()
                }
            }
        }
        .padding(.vertical, Design.Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint)
    }
}
