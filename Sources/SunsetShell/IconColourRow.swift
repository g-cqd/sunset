import SunsetPane
import SwiftUI

/// The colour of a symbol: the presets, any colour, and none (the symbol's own).
struct IconColourRow: View {
    @Binding var color: IconColor?

    /// The presets' names, in their order.
    static let names = ["Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple", "Pink", "Grey"]

    var body: some View {
        HStack(spacing: Design.Space.s) {
            ForEach(Array(IconPicker.presets.enumerated()), id: \.element) { index, preset in
                Circle()
                    .fill(Color(preset))
                    .frame(width: 16, height: 16)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                .primary.opacity(color == preset ? Design.Fill.accentPressed : 0),
                                lineWidth: 2
                            )
                    }
                    .onTapGesture { color = preset }
                    .accessibilityElement()
                    .accessibilityLabel(Self.names[index])
                    .accessibilityAddTraits(color == preset ? [.isButton, .isSelected] : .isButton)
                    .accessibilityAction { color = preset }
            }
            ColorPicker(
                "",
                selection: Binding(
                    get: { color.map { Color($0) } ?? .secondary },
                    set: { if let picked = IconColor($0) { color = picked } }
                ),
                supportsOpacity: false
            )
            .labelsHidden()
            SwiftUI.Button("None") { color = nil }.buttonStyle(.borderless).font(Design.Text.detail)
        }
    }
}
