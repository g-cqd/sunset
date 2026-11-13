import AemiSDR
import SwiftUI

/// The look of `View.barGroup(margin:top:)`.
struct BarGroup: ViewModifier {
    let margin: Double
    let top: Bool
    @Environment(\.barBlur) private var choice

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: Self.shape)
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

    /// Concentric with the container's corners, never tighter than a leaf's.
    static var shape: ConcentricRectangle {
        ConcentricRectangle(corners: .concentric(minimum: .fixed(Design.Blur.groupMinimumRadius)), isUniform: true)
    }

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
