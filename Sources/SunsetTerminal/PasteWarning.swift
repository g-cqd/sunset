import AppKit
import SunsetCore
package import SunsetShell
import SunsetShellModel

/// The question before a risky paste (task t116): a sheet on the terminal's window naming each risk and showing the text as
/// it would be sent, in Sunset's look (the owner's note n73). Cancel is the default: Return does not paste.
@MainActor
package enum PasteWarning {
    /// How the app draws its alerts (its surface); the default look until it says.
    package static var style = SurfaceStyle()

    static func ask(_ risks: [PasteRisk], _ text: String, in window: NSWindow?, paste: @escaping @MainActor () -> Void)
    {
        let alert = SunsetAlert(
            title: PasteRisk.title(of: risks),
            message: risks.map(\.sentence).joined(separator: "\n\n"),
            preview: PasteRisk.preview(text),
            buttons: [.cancel("Cancel"), .plain("Paste")],
            defaultButton: 0
        )
        SunsetAlertSheet.show(alert, on: window, style: style) { pressed in
            if pressed == 1 { paste() }
        }
    }
}
