extension Configuration.Web {
    /// `web.pageScheme`: the scheme pages are shown in (design 0009): Sunset's own, the system's, or light or dark. A page
    /// with a dark mode of its own uses it; the others are left as they are.
    public enum PageScheme: String, Sendable, Equatable, CaseIterable {
        case app, system, light, dark
    }
}
