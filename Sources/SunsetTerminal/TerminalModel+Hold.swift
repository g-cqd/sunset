package import CoreGraphics
import SunsetCore

extension TerminalModel {
    /// Keeps the grid as it is while a layout change animates, then sizes it once to what the view became.
    package func holdResize(for duration: Duration) {
        holdsResize = true
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard let self else { return }
            holdsResize = false
            viewResized(pixelWidth: viewPixels.width, pixelHeight: viewPixels.height, scale: scale)
        }
    }
}

extension TerminalModel {
    /// The terminal's default background, with the window's opacity, as the colour of the view's layer.
    package var layerBackground: CGColor {
        let rgb = defaultColors.background ?? lastScreen?.palette.background ?? RGB(0, 0, 0)
        return CGColor(
            srgbRed: Double(rgb.red) / 255,
            green: Double(rgb.green) / 255,
            blue: Double(rgb.blue) / 255,
            alpha: Double(backgroundAlpha) / 255
        )
    }
}
