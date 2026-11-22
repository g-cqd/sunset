import AppKit
import SunsetPane
import SunsetShellModel
import SunsetWeb

/// The pages extensions open (`tabs.create`, a link in a popup, an options page): a tab of a window of the extension's
/// profile (the one it names, else the one in front, else the first), right after the page it shows, the window brought
/// forward when the tab is to be active. None when no window of the profile is open.
@MainActor
enum AppExtensionTabs {
    static func start() {
        ExtensionHosts.shared.openTab = { url, window, profile, active in
            open(url, in: window, profile: profile, active: active)
        }
    }

    static func open(_ url: URL?, in named: ExtensionWindow?, profile: UUID?, active: Bool) -> WebContent? {
        let windows = TabRegistry.shared.allWindows()
            .filter {
                !$0.tabs.isPrivateWindow && PaneContentKinds.profile(of: $0.tabs) == profile
            }
        let key = NSApp.keyWindow
        guard
            let (window, tabs) = windows.first(where: { $0.window === named?.window })
                ?? windows.first(where: { $0.window === key }) ?? windows.first
        else { return nil }
        let descriptor = PaneDescriptor(kind: WebContent.kind, state: url.map { ["url": $0.absoluteString] } ?? [:])
        guard
            let page = PaneContentKinds.make(
                descriptor,
                profile: profile,
                changed: { SessionStore.shared.scheduleSave() }
            )
                as? WebContent
        else { return nil }
        WebOpening.wire(page, in: tabs)
        if let shown = tabs.selectedContent {
            tabs.insertTab(page, after: shown, show: active)
        } else {
            tabs.insertTab(page, after: page, show: active)
        }
        if active { window.makeKeyAndOrderFront(nil) }
        ExtensionHosts.shared.sync()
        return page
    }
}
