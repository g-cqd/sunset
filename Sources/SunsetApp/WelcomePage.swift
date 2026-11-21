import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// One page of the welcome: where it is in the welcome, its question, a line about it, then its controls.
struct WelcomePage: View {
    let step: WelcomeStep
    let position: Int
    let count: Int
    let greeting: WelcomeGreeting
    let store: AppConfiguration
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Welcome.section) {
            VStack(alignment: .leading, spacing: Design.Space.s) {
                Text("\(position) of \(count)").font(.subheadline).foregroundStyle(.secondary)
                Text(text.title).font(.largeTitle.bold())
                Text(text.line)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            controls.frame(maxWidth: Design.Welcome.column, alignment: .leading)
        }
        .foregroundStyle(.primary)
    }

    /// The page's question and line; the first page's, the easter egg's own.
    private var text: (title: String, line: String) {
        step == .hello ? greeting.text : Self.text(step)
    }

    @ViewBuilder private var controls: some View {
        switch step {
            case .hello, .done: EmptyView()
            case .features: WelcomeFeatures(store: store)
            case .security: WelcomeSecurity(store: store)
            case .defaultBrowser: WelcomeDefaultBrowser()
            case .search: WelcomeSearch(store: store)
            case .start: WelcomeStart(store: store)
            case .importing:
                Button("Import from Another Browser\u{2026}") {
                    close()
                    AppActions.shared.importFromBrowser()
                }
                .buttonStyle(.glass)
                .controlSize(.large)
        }
    }

    /// Each page's question and the line under it.
    private static func text(_ step: WelcomeStep) -> (title: String, line: String) {
        switch step {
            case .hello: WelcomeGreeting.first.text
            case .features: ("What will you use?", "Turn on what you need. The rest stays out of the menus.")
            case .security:
                ("How careful should it be?", "One choice for the settings that weigh safety against pages working.")
            case .defaultBrowser:
                ("Open links in Sunset?", "Links from other apps would open here. macOS asks you to confirm.")
            case .search: ("Search with", "Where words typed in the address bar go. Others can be added in Settings.")
            case .start: ("When Sunset opens", "What opens when there is no tab.")
            case .importing:
                (
                    "Bring your things",
                    "Bookmarks and extensions from Safari, Chrome, Firefox and others, into a Space of their own."
                )
            case .done: ("You\u{2019}re set", "Help \u{25B8} Welcome to Sunset brings this back.")
        }
    }
}
