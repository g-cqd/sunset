import SunsetHelp
import SwiftUI

/// A topic's text in a popover (`HelpButton`): the title, the plain paragraphs, the part for experienced people folded.
struct HelpPopover: View {
    let topic: HelpTopic
    @State private var showsExpert = false

    var body: some View {
        let entry = HelpCatalog.entry(topic)
        VStack(alignment: .leading, spacing: Design.Space.m) {
            Text(entry.title).font(.headline)
            ForEach(Array(entry.text.enumerated()), id: \.offset) { _, paragraph in
                Text(RichText.attributed(paragraph)).fixedSize(horizontal: false, vertical: true)
            }
            if !entry.expert.isEmpty {
                // As wide as the popover, as its other paragraphs (the owner's note n62).
                Fold("For experienced users", isExpanded: $showsExpert) {
                    VStack(alignment: .leading, spacing: Design.Space.s) {
                        ForEach(Array(entry.expert.enumerated()), id: \.offset) { _, paragraph in
                            Text(RichText.attributed(paragraph)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(Design.Space.l)
        .frame(width: Design.Size.helpPopoverWidth, alignment: .leading)
    }
}
