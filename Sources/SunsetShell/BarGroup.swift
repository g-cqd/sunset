import AemiSDR
import SwiftUI

/// The look of `View.barGroup(margin:top:)`.
struct BarGroup: ViewModifier {
    let margin: Double
    let top: Bool
    @Environment(\.barBlur) private var choice

    func body(content: Content) -> some View {
        content
            // Tinted dark, so that its text and icons read over a light page (owner, 2026-11-13: contrast).
            .background { Self.shape.fill(.black.opacity(Design.Fill.barShade)) }
            .glassEffect(.regular, in: Self.shape)
            .environment(\.colorScheme, .dark)
            // Its controls are capsules too: half their height, concentric with the group at the container inset.
            .environment(\.controlRadius, Design.Size.field / 2)
            .background {
                if choice == .variable {
                    GeometryReader { proxy in
                        BlurBackdropView(Design.Blur.group(size: proxy.size, margin: margin, top: top))
                    }
                    .padding(outsets)
                    .allowsHitTesting(false)
                }
            }
    }

    /// A capsule, as the system's toolbar groups (owner, 2026-11-13).
    static var shape: Capsule { Capsule() }

    private var outsets: EdgeInsets {
        let reach = Design.Blur.groupReach
        let fall = Design.Blur.groupFall
        return EdgeInsets(
            top: -(top ? margin : fall),
            leading: -reach,
            bottom: -(top ? fall : margin),
            trailing: -reach
        )
    }
}
