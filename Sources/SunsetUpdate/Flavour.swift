/// Which of Sunset's releasables an asset is: the app on the system's WebKit, Sunset WebKit with its own, or the WebKit
/// engine as a component beside the app (roadmap 0113).
public enum Flavour: String, Sendable, CaseIterable {
    case native = "Sunset"
    case webKit = "Sunset-WebKit"
    case engine = "SunsetEngine"

    /// The start of its archives' names: `Sunset-v0.1.0-build786-macos-arm64.zip`, `Sunset-WebKit-v0.1.0-…`.
    public var assetPrefix: String {
        rawValue + "-"
    }
}
