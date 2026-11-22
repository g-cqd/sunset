import SunsetShell
import SwiftUI

/// The address of the link under the pointer, at the bottom of its page: one line, plain text.
struct LinkStatusLabel: View {
    let text: String
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: surface.leafRadius, style: .continuous)
        Text(verbatim: text)
            .font(Design.Text.detail)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, Design.Space.m)
            .padding(.vertical, Design.Space.xs)
            // A material, not glass: glass over a white page left white text on light grey.
            .background(.thickMaterial, in: shape)
            .overlay { shape.hairline(surface.layout) }
            .padding(Design.Space.m)
            .allowsHitTesting(false)
    }
}
