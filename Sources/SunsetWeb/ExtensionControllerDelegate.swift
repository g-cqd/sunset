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

    /// A tab an extension opens (`tabs.create`, a link in its popup): the app opens the page in the window named, else
    /// the one in front, of the extension's profile.
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewTabUsing configuration: WKWebExtension.TabConfiguration,
        for context: WKWebExtensionContext
    ) async throws -> (any WKWebExtensionTab)? {
        guard let host else { return nil }
        let window = configuration.window as? ExtensionWindow
        let page = ExtensionHosts.shared.openTab(configuration.url, window, host.profile, configuration.shouldBeActive)
        return page?.extensionTab
    }

    /// A window an extension opens (`windows.create`): its first address as a tab of the window in front, as Sunset's own
    /// opened pages go (a window per extension call would pile up).
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewWindowUsing configuration: WKWebExtension.WindowConfiguration,
        for context: WKWebExtensionContext
    ) async throws -> (any WKWebExtensionWindow)? {
        guard let host else { return nil }
        let page = ExtensionHosts.shared.openTab(
            configuration.tabURLs.first,
            nil,
            host.profile,
            configuration.shouldBeFocused
        )
        guard let page else { return nil }
        return ExtensionHosts.shared.window(of: page)
    }

    /// The extension's options page (`runtime.openOptionsPage`, its menu's Options), as a tab of the window in front.
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openOptionsPageFor context: WKWebExtensionContext
    ) async throws {
        guard let host, let url = context.optionsPageURL else { return }
        _ = ExtensionHosts.shared.openTab(url, nil, host.profile, true)
    }
}
