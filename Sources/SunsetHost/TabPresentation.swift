public import SunsetConfig

/// How the tabs are shown, worked out from the configuration. Native tabs and the sidebar are two views of the same tabs; the built-in bar excludes both.
public enum TabPresentation: Sendable, Equatable {
    /// One terminal per window.
    case windows
    /// The system's tab bar.
    case nativeTabs
    /// A vertical sidebar listing the tabs of the window.
    case sidebar
    /// A tab bar of our own in the terminal window.
    case builtInBar

    public static func resolve(mode: Configuration.Tabs.Mode, sidebar: Bool) -> TabPresentation {
        switch mode {
            case .none: .windows
            case .native: sidebar ? .sidebar : .nativeTabs
            case .internal: .builtInBar
        }
    }

    public var showsNativeTabBar: Bool { self == .nativeTabs }
    public var showsSidebar: Bool { self == .sidebar }
    public var showsBuiltInBar: Bool { self == .builtInBar }
    /// Windows are grouped by the system (`NSWindow.tabbingMode`).
    public var usesSystemTabbing: Bool { self == .nativeTabs }

    /// All the tabs of a window are terminals of that one window (the sidebar and the built-in bar list them); with `false` each tab is a window of its own.
    public var hostsTabsInWindow: Bool { self == .sidebar || self == .builtInBar }
}
