import SunsetConfig
import SunsetMetrics
import SunsetShell
import SwiftUI

/// What the look settings make of a window in a scheme (design 0009), drawn small above them: the background with its
/// tint, a sidebar, and the terminal with its colors.
struct SchemePreview: View {
    /// The configuration as it is in that scheme.
    let look: Configuration
    let light: Bool
    let layout: LayoutMetrics

    /// Its height: a window in a few lines.
    private static let height = 96.0

    var body: some View {
        let outer = RoundedRectangle(cornerRadius: Design.Radius.surface(layout), style: .continuous)
        ZStack {
            outer.fill(background)
            if let tint = look.appearance.tintColor {
                outer.fill(Color(sRGBBytes: tint).opacity(look.appearance.tintAlpha))
            }
            HStack(spacing: Design.Space.s) {
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        Capsule().fill(.secondary.opacity(0.3)).frame(height: Design.Space.xs)
                    }
                    Spacer()
                }
                .frame(width: Self.height * 0.6)
                terminal
            }
            .padding(Design.Space.s)
        }
        .frame(height: Self.height)
        .environment(\.colorScheme, light ? .light : .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(light ? "Preview in light" : "Preview in dark")
    }

    /// Under the tint: a material for a material or glass, else the window's own color (a tint replaces it).
    private var background: AnyShapeStyle {
        switch look.window.material {
            case .material, .glass: AnyShapeStyle(.regularMaterial)
            case .color: AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var terminal: some View {
        let colors = look.colors
        let screen = RoundedRectangle(cornerRadius: Design.Radius.leaf(layout), style: .continuous)
        return VStack(alignment: .leading, spacing: Design.Space.xs) {
            Text("~ % ls").foregroundStyle(colors.foreground.map { Color(sRGBBytes: $0) } ?? .primary)
            HStack(spacing: Design.Space.xs) {
                ForEach(0 ..< 8, id: \.self) { index in
                    Circle().fill(Color(sRGBBytes: colors.ansi[index])).frame(width: Design.Space.m)
                }
            }
            Spacer()
        }
        .font(Design.Text.detail.monospaced())
        .padding(Design.Space.s)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(screen.fill(screenColor))
    }

    /// The terminal's background at its opacity.
    private var screenColor: Color {
        guard let bytes = look.colors.background else { return .clear }
        return Color(sRGBBytes: bytes).opacity(look.terminal.opacity)
    }
}
