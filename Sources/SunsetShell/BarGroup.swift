import AemiSDR
import SwiftUI

/// The look of `View.barGroup(margin:top:)`.
struct BarGroup: ViewModifier {
    let margin: Double
    let top: Bool
    @Environment(\.barBlur) private var choice
    @Environment(\.barGroupBlursBelow) private var blursBelow
    @Environment(\.barTint) private var tint
    @Environment(\.colorScheme) private var outer

    func body(content: Content) -> some View {
        let scheme = tint.resolved(in: outer)
        content
            // The controls' scheme set on them, inside the glass: set outside, the glass gave its content the window's.
            .environment(\.colorScheme, scheme)
            // Tinted to the controls' scheme, so that they read over any page (owner, 2026-11-13: contrast).
            .background { Self.shape.fill(BarTint.fill(for: scheme).opacity(Design.Fill.barShade)) }
            .glassEffect(.regular, in: Self.shape)
            .environment(\.controlRadius, Design.BarGroup.control / 2)
            .environment(\.controlHeight, Design.BarGroup.control)
            .environment(\.controlPadding, Design.BarGroup.fieldPadding)
            .background {
                if choice == .variable, !blursBelow {
                    GeometryReader { proxy in
                        BlurBackdropView(Design.Blur.group(size: proxy.size, margin: margin, top: top))
                    }
                    .padding(Self.outsets(margin: margin, top: top).negated)
                    .allowsHitTesting(false)
                }
            }
            .anchorPreference(key: BarGroupBlurs.Key.self, value: .bounds) { bounds in
                blursBelow ? [BarGroupBlurs.Entry(bounds: bounds, margin: margin, top: top)] : []
            }
    }

    /// A capsule, as the system's toolbar groups (owner, 2026-11-13).
    static var shape: Capsule { Capsule() }

    /// How far a group's blur reaches past it on each side: `margin` to the container's edge, its fall away from it, its reach at
    /// both ends.
    static func outsets(margin: Double, top: Bool) -> EdgeInsets {
        let reach = Design.Blur.groupReach
        let fall = Design.Blur.groupFall
        return EdgeInsets(top: top ? margin : fall, leading: reach, bottom: top ? fall : margin, trailing: reach)
    }
}

extension EdgeInsets {
    fileprivate var negated: EdgeInsets {
        EdgeInsets(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
    }
}
