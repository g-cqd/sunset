package import SunsetPane

/// The sections of the sidebars by the scope of the app they belong to (roadmap 0033; ADR-0056).
extension SidebarSection {
    /// History and Downloads are the web's, Documents the documents'; the tabs and the settings are no scope's.
    package var scope: Scopes.Scope? {
        switch self {
            case .documents: .documents
            case .history, .downloads: .web
            case .tabs, .settings: nil
        }
    }

    package func isShown(for scopes: Scopes) -> Bool {
        scope.map { scopes[$0] } ?? true
    }

    /// The Library's rail with these scopes on: the tabs alone is no Library.
    package static func rail(for scopes: Scopes) -> [Self] {
        rail.filter { $0.isShown(for: scopes) }
    }

    /// The sections of the panel opposite the tabs with these scopes on.
    package static func panel(for scopes: Scopes) -> [Self] {
        panel.filter { $0.isShown(for: scopes) }
    }
}
