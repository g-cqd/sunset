import SunsetHelp
import SunsetShell
import SwiftUI

/// One topic's text in Help's page: its summary, its paragraphs (a "• " one a list item), the part for experienced people,
/// and the topics it leads to as links.
struct HelpTopicView: View {
    let topic: HelpTopic
    let open: (HelpTopic) -> Void

    var body: some View {
        let entry = HelpCatalog.entry(topic)
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text(entry.title).font(.title2.weight(.semibold))
            Text(entry.summary).font(.headline).foregroundStyle(.secondary)
            paragraphs(entry.text)
            if !entry.expert.isEmpty {
                Text("For experienced users").font(.headline)
                paragraphs(entry.expert)
            }
            if !entry.related.isEmpty {
                Text("See also").font(.headline)
                ForEach(entry.related) { other in
                    Button(HelpCatalog.entry(other).title) { open(other) }.buttonStyle(.link)
                }
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: Design.Size.helpTextWidth, alignment: .leading)
        .padding(Design.Space.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paragraphs(_ text: [String]) -> some View {
        ForEach(Array(text.enumerated()), id: \.offset) { _, paragraph in
            Text(paragraph).fixedSize(horizontal: false, vertical: true)
        }
    }
}
