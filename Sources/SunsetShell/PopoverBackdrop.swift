import SwiftUI

/// The presentation background of a popover, aligned with floating preview cards (`Design.Fill.popoverShade`).
struct PopoverBackdrop: View {
    @Environment(\.surfaceStyle) private var surface
    @Environment(\.barTint) private var barTint
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        SurfaceFill(shape: Rectangle(), style: surface, shade: barTint.shaded(in: scheme).shade)
    }
}
