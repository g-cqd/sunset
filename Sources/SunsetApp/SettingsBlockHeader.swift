import SunsetConfig
import SunsetHelp
import SunsetShell
import SwiftUI

/// Above a block of Settings: the page's heading over the first one, and the block's own heading, with the "?" of the help
/// that explains the whole block (a list's) after it, not beside one of its controls.
struct SettingsBlockHeader: View {
    let page: String?
    let block: SettingsBlock

    /// A list's help; a group's options each have their own.
    private var help: HelpTopic? {
        guard block.isList, let list = block.options.first else { return nil }
        return HelpTopic.explaining(setting: list.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            if let page { Text(page).font(Design.Text.heading).foregroundStyle(.primary) }
            if let title = block.title { SettingsLabel(title, help: help) }
        }
    }
}
