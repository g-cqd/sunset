import SunsetPane
package import SwiftUI

/// Where a drag would land: a white veil and a white edge, blended with what is under them (lighter on the dark chrome,
/// never a colour of its own).
package struct DropVeil<S: InsettableShape>: View {
    let shape: S

    package init(shape: S) {
        self.shape = shape
    }

    package var body: some View {
        shape.fill(.white.opacity(Design.Fill.dropVeil))
            .overlay { shape.strokeBorder(.white.opacity(Design.Fill.dropEdge), lineWidth: 1) }
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    /// Overlay for a kept entry's drop action (`FavoritesSection` rows use `vertical: true`, `PinnedGrid` tiles `vertical: false`).
    @ViewBuilder static func entryOverlay(
        id: Favorites.NodeID,
        active: (owner: Favorites.NodeID, place: TabDropAction)?,
        cornerRadius: Double,
        accent: Color,
        vertical: Bool,
        gapOffset: Double
    ) -> some View {
        if let active, active.owner == id {
            switch active.place {
                case .split(let edge):
                    GeometryReader { proxy in
                        let half = proxy.size.width / 2
                        DropVeil<RoundedRectangle>(
                            shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        )
                        .frame(width: half, height: proxy.size.height)
                        .offset(x: edge == .right ? half : 0)
                    }
                    .allowsHitTesting(false)
                case .moveBefore, .moveAfter:
                    let after = active.place == .moveAfter
                    if vertical {
                        VStack {
                            if after { Spacer(minLength: 0) }
                            Capsule().fill(accent).frame(height: Design.Space.hair)
                                .padding(.horizontal, Design.Space.xs)
                            if !after { Spacer(minLength: 0) }
                        }
                        .padding(.vertical, -gapOffset)
                        .allowsHitTesting(false)
                    } else {
                        HStack {
                            if after { Spacer(minLength: 0) }
                            Capsule()
                                .fill(accent)
                                .frame(width: Design.Space.hair)
                                .padding(.vertical, Design.Space.xs)
                                .offset(x: (after ? 1 : -1) * gapOffset)
                            if !after { Spacer(minLength: 0) }
                        }
                        .allowsHitTesting(false)
                    }
            }
        }
    }
}
