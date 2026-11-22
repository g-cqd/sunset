extension Configuration.Sidebar {
    /// How the Spaces show at the sidebar's foot (`sidebar.spaces`): their icons, dots once they do not fit, the shown one
    /// keeping its icon; or dots always, the shown one prominent.
    public enum SpacesStyle: String, Sendable, Equatable, CaseIterable {
        case auto, dots
    }
}
