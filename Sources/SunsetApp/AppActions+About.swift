import AppKit

extension AppActions {
    /// The standard About panel; Sunset WebKit's names its engine and its date.
    func showAbout() {
        var options: [NSApplication.AboutPanelOptionKey: Any] = [:]
        if let line = AppEngineFreshness.aboutLine {
            options[.credits] = NSAttributedString(
                string: line,
                attributes: [
                    .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
        }
        NSApp.orderFrontStandardAboutPanel(options: options)
    }
}
