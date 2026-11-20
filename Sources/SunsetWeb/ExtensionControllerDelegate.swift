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
}
