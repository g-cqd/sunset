import SwiftUI

/// The look of `View.fieldSurface(dark:height:)`.
struct FieldSurface: ViewModifier {
    let dark: Bool
    let height: Double?
    @Environment(\.surfaceStyle) private var surface
    @Environment(\.controlRadius) private var controlRadius

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: controlRadius ?? surface.leafRadius, style: .continuous)
        content
            .padding(.horizontal, Design.Space.m)
            .frame(height: height.map { CGFloat($0) })
            .background(
                shape.fill(dark ? Color.black.opacity(Design.Fill.darkField) : Color.primary.opacity(Design.Fill.field))
            )
            .overlay { shape.hairline(surface.layout) }
            .clipShape(shape)
    }
}
