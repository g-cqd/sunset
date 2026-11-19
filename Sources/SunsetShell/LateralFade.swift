import SwiftUI

/// The mask of the sidebar's list while it swipes between Spaces (the owner, 2026-11-17): the rows are cut at the sidebar's
/// sides and fade there, instead of passing under the panes. At rest the mask reaches past the sides, so nothing is cut (a
/// drop's outline is drawn past the rows). From one to the other the two masks are cross-faded, their edges where they are
/// (roadmap 0047 C: moving the edges 400 points out took the fade off the sidebar in the first frames).
struct LateralFade: View {
    let sliding: Bool

    /// Its measures.
    struct Shape: Equatable {
        /// How wide the fade at each side is.
        let fade: Double
        /// How far past the sides (and always past the top and bottom) the mask reaches.
        let overhang: Double

        init(sliding: Bool) {
            fade = sliding ? Design.Space.l : 0
            overhang = sliding ? 0 : Self.far
        }

        static let far = 400.0
    }

    /// How much of each mask counts: the cut one while sliding, the open one at rest (drawn over the cut one).
    struct Weights: Equatable {
        let cut: Double
        let open: Double

        init(cut: Double, open: Double) {
            self.cut = cut
            self.open = open
        }

        init(sliding: Bool) {
            self.init(cut: sliding ? 1 : 0, open: sliding ? 0 : 1)
        }
    }

    var body: some View {
        let weights = Weights(sliding: sliding)
        // The cut mask is always drawn (the rows inside it never dim while the two blend); the open one over it, by its weight.
        ZStack {
            mask(Shape(sliding: true))
            mask(Shape(sliding: false)).opacity(weights.open)
        }
    }

    private func mask(_ shape: Shape) -> some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing).frame(width: shape.fade)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: shape.fade)
        }
        .padding(.horizontal, -shape.overhang)
        .padding(.vertical, -Shape.far)
    }
}
