import SunsetMetrics
package import SwiftUI

/// A small button of a row, as a tab's close button is (roadmap 0047 F): a glyph on nothing at rest, a rounded fill under the
/// pointer, darker pressed. The address field's lock, Copy and Reload are these.
package struct RowGlyphButton<Glyph: View>: View {
    let help: String
    let action: () -> Void
    let glyph: Glyph
    @Environment(\.surfaceStyle) private var surface

    package init(help: String, action: @escaping () -> Void, @ViewBuilder glyph: () -> Glyph) {
        self.help = help
        self.action = action
        self.glyph = glyph()
    }

    package var body: some View {
        Button(action: action) { glyph }
            .buttonStyle(Style(layout: surface.layout))
            .help(help)
    }

    private struct Style: ButtonStyle {
        let layout: ShellSettings.Layout

        func makeBody(configuration: Configuration) -> some View {
            Face(label: configuration.label, pressed: configuration.isPressed, layout: layout)
        }
    }

    private struct Face<Label: View>: View {
        let label: Label
        let pressed: Bool
        let layout: ShellSettings.Layout
        @State private var hovering = false

        var body: some View {
            label
                .font(.system(size: Design.Symbol.badge, weight: .semibold))
                .foregroundStyle(hovering || pressed ? .primary : .secondary)
                .frame(minWidth: layout.closeButtonSize, minHeight: layout.closeButtonSize)
                .background(
                    RoundedRectangle(cornerRadius: layout.closeButtonRadius, style: .continuous)
                        .fill(.primary.opacity(pressed ? Design.Fill.pressed : hovering ? Design.Fill.selected : 0))
                )
                .contentShape(.rect)
                // The press is felt (the owner's note n11).
                .scaleEffect(pressed ? Design.Motion.pressedScale : 1)
                .onHover { hovering = $0 }
                .animation(layout.smooth, value: hovering)
                .animation(.snappy(duration: 0.12), value: pressed)
        }
    }
}

extension RowGlyphButton where Glyph == Image {
    /// A button of one symbol.
    package init(symbol: String, help: String, action: @escaping () -> Void) {
        self.init(help: help, action: action) { Image(systemName: symbol) }
    }
}
