package import SunsetMetrics
package import SwiftUI

/// How the window's floating parts are drawn (design 0003 §6): one choice, `window.material`, for every surface, with the glass's variant and the
/// tint. Set at the window's root; bars, panels and lists read it from the environment.
package struct SurfaceStyle: Sendable, Equatable {
    package var kind = Design.Surface.glass
    /// Glass: the clear variant instead of the regular one.
    package var clearGlass = false
    /// The tint as sRGB components and alpha (0 to 1); a fill draws it, nil for none.
    package var tint: [Double]?
    /// The window's measures: the hairline, and the leaf radius the surfaces' corners are derived from.
    package var layout = LayoutMetrics()

    package init(
        kind: Design.Surface = .glass,
        clearGlass: Bool = false,
        tint: [Double]? = nil,
        layout: LayoutMetrics = LayoutMetrics()
    ) {
        self.kind = kind
        self.clearGlass = clearGlass
        self.tint = tint
        self.layout = layout
    }

    /// The corner of a floating surface holding leaves at the container inset.
    package var radius: Double { Design.Radius.surface(layout) }
    /// The corner of a leaf inside it (a row, a field).
    package var leafRadius: Double { Design.Radius.leaf(layout) }
    /// A panel: what it holds is `Design.Space.xl` from its edge, so its corner is the leaf's plus that (the buttons in its corner nest).
    package var panelRadius: Double { Design.Radius.container(holding: leafRadius, inset: Design.Space.xl) }
    package var panelShape: RoundedRectangle { RoundedRectangle(cornerRadius: panelRadius, style: .continuous) }
    /// The surface's shape.
    package var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .continuous) }

    /// The colour of a fill: the tint, or half-black without one.
    package var fillColor: Color {
        guard let tint, tint.count == 4 else { return .black.opacity(Design.Fill.untinted) }
        return Color(.sRGB, red: tint[0], green: tint[1], blue: tint[2], opacity: tint[3])
    }
}

extension EnvironmentValues {
    @Entry package var surfaceStyle = SurfaceStyle()
}
