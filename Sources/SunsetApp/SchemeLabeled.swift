import SunsetShell
import SwiftUI

/// A control under the scheme it sets: a sun for light, a moon for dark.
struct SchemeLabeled<Content: View>: View {
    let light: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Space.xs) {
            Image(systemName: light ? "sun.max" : "moon")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            content()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(light ? "In light" : "In dark")
    }
}
