import SunsetShell
import SwiftUI

/// A site's own rule under a default: the host indented on the leading edge, its choice and a remove button on the
/// trailing one.
struct SiteRuleRow<Choice: View>: View {
    let host: String
    @ViewBuilder let choice: () -> Choice
    let remove: () -> Void

    var body: some View {
        LabeledContent {
            HStack(spacing: Design.Space.s) {
                choice().labelsHidden().fixedSize()
                Button(action: remove) { Image(systemName: "minus.circle") }
                    .buttonStyle(.borderless)
                    .help("Remove: the default applies again")
                    .accessibilityLabel("Remove the rule of \(host)")
            }
        } label: {
            Text(host).foregroundStyle(.secondary).padding(.leading, Design.Optical.siteRowsIndent)
        }
    }
}
