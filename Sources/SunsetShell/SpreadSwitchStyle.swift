package import SwiftUI

/// A switch on the trailing edge and its text on the leading edge, the width between them (the owner's note n45: in a
/// popover the switches sat right after their text). With its label hidden (a settings row, where the row's label is the
/// text), the switch alone.
package struct SpreadSwitchStyle: ToggleStyle {
    @Environment(\.labelsVisibility) private var labels

    package init() {}

    package func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Design.Space.m) {
            if labels != .hidden {
                configuration.label
                Spacer(minLength: 0)
            }
            // Only the switch is small: its label is in the row's font, as the other rows' (the owner's note n62).
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
    }
}
