import SunsetShell
import SwiftUI

/// A name and a line about it: a switch's or a radio button's label in the welcome.
struct WelcomeOption: View {
    let title: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.hair) {
            Text(title).font(.body.weight(.medium))
            if let detail { Text(detail).font(.callout).foregroundStyle(.secondary) }
        }
    }
}
