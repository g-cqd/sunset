import SunsetCore

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
}
