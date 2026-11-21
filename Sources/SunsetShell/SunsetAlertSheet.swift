package import AppKit
package import SunsetShellModel
import SwiftUI

/// Shows a Sunset alert (the owner's note n73) as a sheet of `window`; with none, in a panel at the screen's centre, run
/// modally. `answer` is called once, with the index of the button pressed.
@MainActor
package enum SunsetAlertSheet {
    package static func show(
        _ alert: SunsetAlert,
        on window: NSWindow?,
        style: SurfaceStyle,
        answer: @escaping @MainActor (Int) -> Void
    ) {
        let sheet = NSPanel(
            contentRect: .zero,
            styleMask: window == nil ? [.titled, .fullSizeContentView] : [.borderless],
            backing: .buffered,
            defer: false
        )
        // One panel: the alert's own surface. The sheet only holds it, drawing nothing and casting no shadow of its own (seen:
        // macOS's sheet frame around Sunset's panel, two windows one in the other).
        sheet.isOpaque = false
        sheet.backgroundColor = .clear
        sheet.hasShadow = false
        sheet.titlebarAppearsTransparent = true
        sheet.titleVisibility = .hidden
        var answered = false
        let finish: (Int) -> Void = { index in
            guard !answered else { return }
            answered = true
            if let window { window.endSheet(sheet) } else { NSApp.stopModal() }
            sheet.orderOut(nil)
            answer(index)
        }
        let host = NSHostingView(
            rootView: SunsetAlertView(alert: alert, answer: finish)
                .environment(\.surfaceStyle, style)
                .padding(Design.Space.l)
        )
        sheet.contentView = host
        sheet.setContentSize(host.fittingSize)
        if let window {
            window.beginSheet(sheet)
        } else {
            sheet.center()
            NSApp.runModal(for: sheet)
        }
    }
}
