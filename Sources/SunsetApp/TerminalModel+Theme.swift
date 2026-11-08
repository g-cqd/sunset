import SunsetCore
import SunsetHost

extension TerminalModel {
    func apply(colors: DefaultColors) {
        guard colors != defaultColors else { return }
        defaultColors = colors
        guard let session else { return }
        Task {
            await colors.apply(to: session)
        }
    }

    func apply(font newFont: FontSettings) {
        guard newFont != font else { return }
        font = newFont
        makeRenderer()
        viewResized(pixelWidth: viewPixels.width, pixelHeight: viewPixels.height, scale: scale)
    }

    func apply(topInset points: Double) {
        guard points != topInsetPoints else { return }
        topInsetPoints = points
        makeRenderer()
        viewResized(pixelWidth: viewPixels.width, pixelHeight: viewPixels.height, scale: scale)
    }

    func apply(padding points: Double) {
        guard points != paddingPoints else { return }
        paddingPoints = points
        makeRenderer()
        viewResized(pixelWidth: viewPixels.width, pixelHeight: viewPixels.height, scale: scale)
    }

    func apply(backgroundAlpha alpha: UInt8) {
        guard alpha != backgroundAlpha else { return }
        backgroundAlpha = alpha
        requestFrame()
    }

    /// The model's settings (colours, padding, alpha, inset) were set directly: bring the renderer, the grid and the colours in line with them.
    func applyLayout() {
        if renderer != nil {
            makeRenderer()
            viewResized(pixelWidth: viewPixels.width, pixelHeight: viewPixels.height, scale: scale)
        }
        if let session {
            let colors = defaultColors
            Task {
                await colors.apply(to: session)
            }
        }
        requestFrame()
    }
}
