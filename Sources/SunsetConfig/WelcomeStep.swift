/// A page of the welcome (roadmap 0111 H), in order.
public enum WelcomeStep: String, Sendable, Equatable, CaseIterable {
    case hello
    case features
    case security
    case defaultBrowser
    /// The search engine words typed in the address bar go to (the owner, 2026-11-21).
    case search
    case start
    case importing
    case done

    /// The pages for what is turned on: the browser's only when web pages are.
    public static func steps(for features: Configuration.Features) -> [Self] {
        features.web ? allCases : allCases.filter { ![.security, .defaultBrowser, .search, .importing].contains($0) }
    }
}
