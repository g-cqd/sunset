import AppKit
import Observation

/// The windows of the app and their tabs, for the sidebar: with system tabs every tab is a window (`NSWindow.tabGroup` groups them), so the sidebar of any
/// window lists the windows of its group and selects one by making it the group's `selectedWindow`. The registry is told when windows come and go and when
/// the key window changes, and bumps `revision` so that views that read it redraw.
@MainActor @Observable
final class TabRegistry {
    static let shared = TabRegistry()

    struct Row: Identifiable {
        let id: ObjectIdentifier
        let window: NSWindow
        let model: (any PaneContent)?
        let isSelected: Bool
    }

    private struct Entry {
        weak var window: NSWindow?
        weak var tabs: TabsModel?
    }

    private(set) var revision = 0
    @ObservationIgnored private var entries: [ObjectIdentifier: Entry] = [:]
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    private init() {
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didBecomeMainNotification] {
            observers.append(
                NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.touch() }
                }
            )
        }
    }

    func register(_ window: NSWindow, tabs: TabsModel) {
        entries[ObjectIdentifier(window)] = Entry(window: window, tabs: tabs)
        touch()
    }

    func unregister(_ window: NSWindow) {
        entries[ObjectIdentifier(window)] = nil
        touch()
    }

    func touch() { revision &+= 1 }

    /// The tabs `window` shows: the windows of its group in the group's order (just itself when it has none).
    func rows(for window: NSWindow?) -> [Row] {
        _ = revision
        guard let window else { return [] }
        let group = window.tabGroup?.windows ?? [window]
        let selected = window.tabGroup?.selectedWindow ?? window
        return group.map { member in
            Row(
                id: ObjectIdentifier(member),
                window: member,
                model: entries[ObjectIdentifier(member)]?.tabs?.selectedContent,
                isSelected: member === selected
            )
        }
    }

    /// The tabs of a window (nil for a window that is not a terminal's, such as Settings).
    func tabs(for window: NSWindow?) -> TabsModel? { window.flatMap { entries[ObjectIdentifier($0)]?.tabs } }

    /// Every terminal window, with its tabs, in the order of the key window's group first, then the others.
    func allWindows() -> [(window: NSWindow, tabs: TabsModel)] {
        var found: [(window: NSWindow, tabs: TabsModel)] = entries.values.compactMap { entry in
            guard let window = entry.window, let tabs = entry.tabs else { return nil }
            return (window, tabs)
        }
        let group = NSApp.keyWindow?.tabGroup?.windows ?? []
        found.sort { first, second in
            let a = group.firstIndex(of: first.window) ?? Int.max
            let b = group.firstIndex(of: second.window) ?? Int.max
            return a == b ? first.window.windowNumber < second.window.windowNumber : a < b
        }
        if let key = NSApp.keyWindow, let index = found.firstIndex(where: { $0.window === key }) {
            found.insert(found.remove(at: index), at: 0)
        }
        return found
    }

    func select(_ window: NSWindow) {
        if let group = window.tabGroup { group.selectedWindow = window } else { window.makeKeyAndOrderFront(nil) }
        touch()
    }

    func close(_ window: NSWindow) { window.performClose(nil) }
}
