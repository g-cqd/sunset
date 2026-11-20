import Foundation
import WebKit

/// WebKit's controller's delegate, an object as WebKit wants, telling the host.
@MainActor final class ExtensionControllerDelegate: NSObject, WKWebExtensionControllerDelegate {
    weak var host: ExtensionHost?

    func webExtensionController(
        _ controller: WKWebExtensionController,
        didUpdate action: WKWebExtension.Action,
        forExtensionContext context: WKWebExtensionContext
    ) {
        host?.revision += 1
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        presentActionPopup action: WKWebExtension.Action,
        for context: WKWebExtensionContext
    ) async throws {
        host?.showPopup(action, for: context)
    }

    /// The profile's windows, the one in front first (WebKit asks: without them an extension sees no tab).
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openWindowsFor context: WKWebExtensionContext
    ) -> [any WKWebExtensionWindow] {
        guard let host else { return [] }
        return ExtensionHosts.shared.windows().filter { $0.profile == host.profile }
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        focusedWindowFor context: WKWebExtensionContext
    ) -> (any WKWebExtensionWindow)? {
        guard let host, let window = ExtensionHosts.shared.focused(), window.profile == host.profile else { return nil }
        return window
    }
}
