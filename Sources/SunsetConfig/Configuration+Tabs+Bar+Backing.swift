extension Configuration.Tabs.Bar {
    /// What is under the built-in bar while it is shown always (roadmap 0055 C).
    public enum Backing: String, Sendable, Equatable, CaseIterable {
        /// The page goes on under the bar, fading under a blur.
        case fade
        /// A native toolbar: the system's bar material, the page below it.
        case toolbar
    }
}
