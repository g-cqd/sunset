import SunsetShell
import SunsetUpdate
import SwiftUI

/// One release's notes in the update window: its name and date, then its blocks (`ReleaseNotes`), inline Markdown kept.
struct ReleaseNotesView: View {
    let release: PublishedRelease
    /// Its name above its notes: when several releases are shown (one alone is named by the window's header).
    var showsTitle = true

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                if showsTitle { Text(release.title).font(.title3.weight(.semibold)) }
                if showsTitle { Spacer() }
                if let published = release.published {
                    Text("Released \(published.formatted(.dateTime.day().month(.wide).year()))")
                        .font(Design.Text.secondary)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(Array(ReleaseNotes.blocks(release.notes).enumerated()), id: \.offset) { _, block in
                view(block)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder private func view(_ block: ReleaseNotes.Block) -> some View {
        switch block {
            case .heading(let text):
                Text(Self.inline(text)).font(.headline).padding(.top, Design.Space.xs)
            case .paragraph(let text):
                Text(Self.inline(text)).fixedSize(horizontal: false, vertical: true)
            case .item(let level, let text):
                HStack(alignment: .firstTextBaseline, spacing: Design.Space.s) {
                    Text(level == 0 ? "\u{2022}" : "\u{25E6}")
                        .foregroundStyle(.secondary)
                        .frame(width: Design.Update.bullet, alignment: .leading)
                    Text(Self.inline(text)).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, Double(level) * Design.Update.indent)
        }
    }

    /// Bold, code and links of a block.
    static func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}
