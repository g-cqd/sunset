import SunsetConfig
import SunsetShell
import SunsetWeb
import SwiftUI

/// The welcome's search question: the engine words typed in the address bar go to (`web.engine`), among the built-in
/// ones and those the person added, as Settings ▸ Web lists them.
struct WelcomeSearch: View {
    let store: AppConfiguration

    var body: some View {
        Picker("Search engine", selection: store.binding(\.web.engine)) {
            ForEach(PaneContentKinds.webSettings.engines, id: \.name) { engine in
                WelcomeOption(title: engine.name, detail: Self.detail(engine.name)).padding(.bottom, Design.Space.xs)
                    .tag(engine.name)
            }
        }
        .pickerStyle(.radioGroup)
        .labelsHidden()
    }

    /// A line about the built-in ones; none for an engine the person added.
    static func detail(_ name: String) -> String? {
        switch name {
            case "Google": "The most results."
            case "DuckDuckGo": "No profile of you is kept."
            case "Bing": "Microsoft\u{2019}s."
            case "Ecosia": "Plants trees with its ad revenue."
            case "Kagi": "Paid, without ads; an account is needed."
            default: nil
        }
    }
}
