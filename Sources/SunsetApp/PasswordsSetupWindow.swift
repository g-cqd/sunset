import AppKit
import SunsetAppCore
import SwiftUI

/// Setting up the vault as a sheet of the window that asked, held by AppKit rather than by the section's view: the
/// section changes as soon as the vault exists (it was seen dropping a SwiftUI sheet, and the recovery code with it,
/// 2026-11-22). The sheet is left out of screen capture: it shows the recovery code.
@MainActor
enum PasswordsSetupWindow {
    static func present(model: PasswordsModel) {
        guard let parent = TabRegistry.shared.actingWindow ?? NSApp.keyWindow else { return }
        let sheet = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        sheet.sharingType = .none
        sheet.contentViewController = NSHostingController(
            rootView: PasswordsSetupSheet(model: model) { [weak parent, weak sheet] in
                if let sheet { parent?.endSheet(sheet) }
            }
        )
        parent.beginSheet(sheet)
    }
}
