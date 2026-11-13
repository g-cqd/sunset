import SwiftUI

/// The look of `View.fieldSurface(dark:height:)`.
struct FieldSurface: ViewModifier {
    let dark: Bool
    let height: Double?
    @Environment(\.surfaceStyle) private var surface
    @Environment(\.controlRadius) private var controlRadius
    @Environment(\.controlHeight) private var controlHeight
    @Environment(\.controlPadding) private var controlPadding

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: controlRadius ?? surface.leafRadius, style: .continuous)
        content
            .padding(.horizontal, controlPadding ?? Design.Space.m)
            .frame(height: height.map { CGFloat(controlHeight ?? $0) })
            .background(
                shape.fill(dark ? Color.black.opacity(Design.Fill.darkField) : Color.primary.opacity(Design.Fill.field))
            )
            .overlay { shape.hairline(surface.layout) }
            .clipShape(shape)
    }
}
