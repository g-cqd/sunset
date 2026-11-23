/// Which of Sunset's apps a release asset is: the one on the system's WebKit, or Sunset WebKit with its own.
public enum Flavour: String, Sendable, CaseIterable {
    case native = "Sunset"
    case webKit = "Sunset-WebKit"

    /// The start of its archives' names: `Sunset-v0.1.0-build786-macos-arm64.zip`, `Sunset-WebKit-v0.1.0-…`.
    public var assetPrefix: String {
        rawValue + "-"
    }
}
