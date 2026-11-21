package import SunsetConfig

/// What Command-T makes (the owner's notes n69–n71), from `tabs.newTab` and the kind of the focused tab.
package enum NewTabKind: Equatable, Sendable {
    case terminal
    case page(isPrivate: Bool)
    case document
    /// Any other content (settings, help).
    case other

    /// The kind a new tab is, from the setting and the focused tab's kind (nil: none focused). A page is private only when
    /// the focused one is.
    package static func resolve(_ setting: Configuration.Tabs.NewTab, focused: Self?) -> Self {
        let focusedPrivate = focused == .page(isPrivate: true)
        switch setting {
            case .terminal:
                return .terminal
            case .web:
                return .page(isPrivate: focusedPrivate)
            case .document:
                return .document
            case .focused:
                switch focused {
                    case .page, .document:
                        return focused ?? .terminal
                    case .terminal, .other, nil:
                        return .terminal
                }
        }
    }
}
