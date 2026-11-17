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
            // The container's height for its fields when it sets one, the field's own given or not (the sidebar's field, a tab's
            // height: roadmap 0035 G).
            .frame(height: (height == nil ? controlHeight : height.map { controlHeight ?? $0 }).map { CGFloat($0) })
            .background(
                shape.fill(dark ? Color.black.opacity(Design.Fill.darkField) : Color.primary.opacity(Design.Fill.field))
            )
            .overlay { shape.hairline(surface.layout) }
            .clipShape(shape)
    }
}
