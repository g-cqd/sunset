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
}
