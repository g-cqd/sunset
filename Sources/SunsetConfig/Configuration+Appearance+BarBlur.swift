extension Configuration.Appearance {
    /// What is under the bars: a blur that fades out, the bar's own surface, or nothing.
    public enum BarBlur: String, Sendable, Equatable, CaseIterable {
        case variable, surface, none
    }
}
