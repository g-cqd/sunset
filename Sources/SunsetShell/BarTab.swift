import SunsetMetrics
import SwiftUI

/// One tab of the built-in bar, drawn as a sidebar row (owner, 2026-11-12: the bar in the sidebar's language): the open fill, the selected
/// fill with the hairline, the leaf corner, the row's height. The close button takes the icon's place under the pointer (and while a close
/// is armed); the icon is back when the pointer leaves.
struct BarTab<Icon: View, Label: View>: View {
    let selected: Bool
    var armed = false
    var button = SidebarRow.Button.close
    /// Nil for a row that has no close button (a folder of the Favorites).
    let close: (() -> Void)?
    @ViewBuilder let icon: Icon
    @ViewBuilder let label: Label
    var lines = 1
    /// A pinned tab of the row of capsules: its icon only, in a circle (its name is its help).
    @Environment(\.tabIconOnly) private var iconOnly
    var onHover: (Bool) -> Void = { _ in }
    @State private var hovering = false
    @State private var overClose = false
    @Environment(\.surfaceStyle) private var surface
    @Environment(\.controlActiveState) private var activeState
    @Environment(\.tabCapsules) private var capsules

    var body: some View {
        let layout = surface.layout
        // In the address row, a capsule as tall as the field, its icon's slot concentric with its rounded end.
        let shape = RoundedRectangle(
            cornerRadius: capsules ? Design.TabCapsules.radius : surface.leafRadius,
            style: .continuous
        )
        let lead =
            capsules
            ? (Design.TabCapsules.height - layout.closeButtonSize) / 2 : layout.tabPaddingLeading - slotOverhang
        HStack(spacing: GlyphSpacing.toText - slotOverhang) {
            ZStack {
                icon.opacity(showsClose ? 0 : 1)
                closeButton.opacity(showsClose ? 1 : 0).allowsHitTesting(showsClose)
            }
            .frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
            if !iconOnly { label.frame(maxWidth: .infinity, alignment: .leading) }
        }
        .padding(.leading, lead)
        .padding(.trailing, iconOnly ? lead : capsules ? Design.BarGroup.fieldPadding : layout.tabPaddingLeading)
        .padding(.vertical, capsules ? 0 : Design.rowPadding(layout, lines: lines, height: Design.Size.tabRow))
        .frame(height: capsules ? Design.TabCapsules.height : nil)
        .background(shape.fill(fill))
        .overlay {
            if armed {
                shape.strokeBorder(Color.red.opacity(Design.Fill.armedLine), lineWidth: 1)
            } else {
                shape.hairline(layout).opacity(selected || capsules ? 1 : 0)
            }
        }
        .contentShape(shape)
        .onHover { inside in
            hovering = inside
            onHover(inside)
        }
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: selected)
        .animation(layout.smooth, value: armed)
    }

    /// The icon's slot is the close button's square, wider than a glyph's frame: it overhangs that frame on each side by this much, which
    /// the gaps give back so that the icon sits where a sidebar row's does.
    private var slotOverhang: Double {
        Design.overhang(of: surface.layout.closeButtonSize, over: Design.Size.glyphFrame)
    }

    private var showsClose: Bool { close != nil && (hovering || armed) }

    private var fill: Color {
        if armed { return .red.opacity(hovering ? Design.Fill.armedHover : Design.Fill.armed) }
        let inactive = activeState == .inactive
        return switch (selected, hovering) {
            case (true, true):
                .primary.opacity(inactive ? Design.Fill.selectedInactiveHover : Design.Fill.selectedHover)
            case (true, false): .primary.opacity(inactive ? Design.Fill.selectedInactive : Design.Fill.selected)
            case (false, true): .primary.opacity(Design.Fill.openHover)
            case (false, false): .primary.opacity(capsules ? Design.Fill.field : Design.Fill.open)
        }
    }

    private var closeButton: some View {
        Button {
            close?()
        } label: {
            Image(systemName: button.symbol)
                .font(.system(size: Design.Symbol.badge, weight: .semibold))
                .foregroundStyle(armed ? Color.white : Color.primary)
                .frame(width: surface.layout.closeButtonSize, height: surface.layout.closeButtonSize)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.small(surface.layout), style: .continuous)
                        .fill(
                            armed
                                ? Color.red.opacity(overClose ? Design.Fill.armedButtonHover : Design.Fill.armedButton)
                                : Color.primary.opacity(overClose ? Design.Fill.selected : 0)
                        )
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { overClose = $0 }
        .help(armed ? "Click again to close running command" : button.help)
    }
}
