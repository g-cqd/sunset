package import SunsetHelp
package import SwiftUI

/// The "?" beside a title or a setting where there is room (roadmap 0041 A; the owner, 2026-11-17): its tooltip is the
/// topic's summary, a click shows the topic's text in a popover, the part for experienced people folded away.
package struct HelpButton: View {
    let topic: HelpTopic
    @State private var shown = false

    package init(_ topic: HelpTopic) {
        self.topic = topic
    }

    package var body: some View {
        Button {
            shown.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .helpTopic(topic)
        .accessibilityLabel("Help: \(HelpCatalog.entry(topic).title)")
        .popover(isPresented: $shown, arrowEdge: .trailing) { HelpPopover(topic: topic).solidPopoverBackground() }
    }
}
