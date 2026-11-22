extension Configuration {
    /// How thick a system material is (`window.materialThickness`).
    public enum MaterialThickness: String, Sendable, Equatable, CaseIterable {
        case ultraThin, thin, regular, thick, ultraThick
    }
}
