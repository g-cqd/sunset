package import AppKit
package import Foundation
package import WebKit

/// A Sunset window as its profile's extensions see one (seen 2026-11-20: with none, uBO Lite's popup found no tab and drew
/// nothing): the pages of the Space it shows as its tabs, the page it shows as the active one. A private window is the
/// private pages'.
@MainActor package final class ExtensionWindow: NSObject, WKWebExtensionWindow {
    private let currentProfile: () -> UUID?
    package var profile: UUID? {
        currentProfile()
    }
    package let isPrivate: Bool
    package let pages: () -> [WebContent]
    package let shown: () -> WebContent?
    package weak var window: NSWindow?

    package init(
        profile: UUID?,
        isPrivate: Bool,
        window: NSWindow? = nil,
        pages: @escaping () -> [WebContent],
        shown: @escaping () -> WebContent?
    ) {
        self.currentProfile = { profile }
        self.isPrivate = isPrivate
        self.window = window
        self.pages = pages
        self.shown = shown
    }

    package init(
        profile: @escaping () -> UUID?,
        isPrivate: Bool,
        window: NSWindow? = nil,
        pages: @escaping () -> [WebContent],
        shown: @escaping () -> WebContent?
    ) {
        self.currentProfile = profile
        self.isPrivate = isPrivate
        self.window = window
        self.pages = pages
        self.shown = shown
    }

    /// Whether `page` is one of its tabs.
    func holds(_ page: WebContent) -> Bool {
        pages().contains { $0 === page }
    }

    package func tabs(for context: WKWebExtensionContext) -> [any WKWebExtensionTab] {
        pages().compactMap(\.extensionTab)
    }

    package func activeTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)? {
        shown()?.extensionTab
    }

    package func windowType(for context: WKWebExtensionContext) -> WKWebExtension.WindowType {
        .normal
    }

    package func windowState(for context: WKWebExtensionContext) -> WKWebExtension.WindowState {
        guard let window else { return .normal }
        if window.styleMask.contains(.fullScreen) { return .fullscreen }
        return window.isMiniaturized ? .minimized : .normal
    }

    package func isPrivate(for context: WKWebExtensionContext) -> Bool {
        isPrivate
    }

    package func frame(for context: WKWebExtensionContext) -> CGRect {
        window?.frame ?? .null
    }

    package func screenFrame(for context: WKWebExtensionContext) -> CGRect {
        window?.screen?.frame ?? .null
    }

    package func focus(for context: WKWebExtensionContext) async throws {
        window?.makeKeyAndOrderFront(nil)
    }
}
