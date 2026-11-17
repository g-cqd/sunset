import SunsetHelp
import SunsetShell
import SwiftUI

/// Help's page (roadmap 0041 E): the topics by area, narrowed by a search, on the left; the chosen topic on the right, the
/// part for experienced people shown, and the topics it leads to.
struct HelpPage: View {
    @Bindable var content: HelpContent

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                TextField("Search Help", text: $content.query)
                    .textFieldStyle(.roundedBorder)
                    .padding(Design.Space.m)
                list
            }
            .frame(width: Design.Size.helpListWidth)
            Divider()
            ScrollView { HelpTopicView(topic: content.topic) { content.topic = $0 } }
                .bouncesOnlyWhenScrolling()
        }
    }

    private var list: some View {
        List(selection: Binding(get: { content.topic }, set: { if let topic = $0 { content.topic = topic } })) {
            ForEach(HelpArea.allCases, id: \.self) { area in
                let topics = content.listed.filter { $0.area == area }
                if !topics.isEmpty {
                    Section(area.title) {
                        ForEach(topics) { Text(HelpCatalog.entry($0).title).tag($0) }
                    }
                }
            }
        }
    }
}
