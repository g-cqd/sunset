import SwiftUI

/// The mask of the sidebar's list while it swipes between Spaces (the owner, 2026-11-17): the rows are cut at the sidebar's
/// sides and fade there, instead of passing under the panes. At rest the mask reaches past the sides, so nothing is cut (a
/// drop's outline is drawn past the rows).
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

    var body: some View {
        let shape = Shape(sliding: sliding)
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing).frame(width: shape.fade)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: shape.fade)
        }
        .padding(.horizontal, -shape.overhang)
        .padding(.vertical, -Shape.far)
    }
}
