import SunsetHelp
import SunsetShell
import SwiftUI

/// A setting's title, and the "?" of the help that explains it right after it: on the leading edge, whatever the control.
struct SettingsLabel: View {
    let title: String
    let help: HelpTopic?

    init(_ title: String, help: HelpTopic? = nil) {
        self.title = title
        self.help = help
    }

    var body: some View {
        HStack(spacing: Design.Space.s) {
            Text(title)
            if let help { HelpButton(help) }
        }
    }
}
