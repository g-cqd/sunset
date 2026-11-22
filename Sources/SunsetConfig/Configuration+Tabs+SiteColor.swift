extension Configuration.Tabs {
    /// A tab coloured by its site: its declared theme colour, else its icon's, when it stands out.
    public enum SiteColor: String, Sendable, Equatable, CaseIterable {
        /// Grey, as every tab.
        case off
        /// The selected tab takes its site's colour.
        case selected
        /// Each tab is faintly in its site's colour, the selected one more.
        case every
    }
}
