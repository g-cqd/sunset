import SunsetCore
import SunsetHost

extension TerminalModel {
    func apply(colors: DefaultColors) {
        guard colors != defaultColors else { return }
        defaultColors = colors
        guard let session else { return }
        Task {
            await session.setDefaultColors(
                foreground: colors.foreground,
                background: colors.background,
                cursor: colors.cursor
            )
        }
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
}
