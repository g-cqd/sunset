import SunsetMetrics
import SunsetPane
import SunsetShellModel
import SwiftUI

/// A Space's colour, in the Space's editor: one for both schemes, or one in dark and one in light (design 0009).
struct SpaceTintPicker: View {
    @Binding var draft: SpaceDraft

    private var separate: Binding<Bool> {
        Binding(
            get: { draft.lightTint != nil },
            set: { on in draft.lightTint = on ? draft.tint ?? IconColor(hex: "#FFFFFF") : nil }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            if draft.lightTint != nil {
                Text("In dark").font(Design.Text.detail).foregroundStyle(.secondary)
            }
            IconColourRow(color: $draft.tint)
            if draft.lightTint != nil {
                Text("In light").font(Design.Text.detail).foregroundStyle(.secondary)
                IconColourRow(color: $draft.lightTint)
            }
            Toggle("Separate for light and dark", isOn: separate).choiceBox()
            Text("Tints the window while it shows this Space.")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
        }
        .padding(Design.Space.xl)
        .solidPopoverBackground()
    }
}
