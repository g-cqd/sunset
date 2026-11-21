import SunsetConfig
import SunsetShell
import SwiftUI

/// The welcome's start question: what opens when there is no tab (`tabs.start`), among what is turned on.
struct WelcomeStart: View {
    let store: AppConfiguration

    private var choices: [(Configuration.Tabs.Start, String)] {
        let features = store.configuration.features
        var all: [(Configuration.Tabs.Start, String)] = [(.nothing, "Nothing")]
        if features.terminal { all.append((.terminal, "A terminal")) }
        if features.web { all.append((.web, "A web page")) }
        if features.documents { all.append((.newDocument, "A new document")) }
        return all
    }

    var body: some View {
        Picker("Open", selection: store.binding(\.tabs.start)) {
            ForEach(choices, id: \.0) { start, title in
                WelcomeOption(title: title).padding(.bottom, Design.Space.xs).tag(start)
            }
        }
        .pickerStyle(.radioGroup)
        .labelsHidden()
    }
}
