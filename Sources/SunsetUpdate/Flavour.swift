/// Which variant of Sunset an asset is (ADR-0125): the native build (system WebKit) or the WebKit-bundled variant
/// (same bundle identifier `studio.aemi.sunset`).
public enum Flavour: String, Sendable, CaseIterable, Codable {
    case native = "Sunset"
    case webKit = "Sunset-WebKit"

    /// The start of its archives' names: `Sunset-v0.1.0-build786-macos-arm64.zip`, `Sunset-WebKit-v0.1.0-…`.
    public var assetPrefix: String {
        rawValue + "-"
    }

    /// Short key prefix in delta archive source maps (`"native-825"`, `"webkit-825"`).
    public var sourceKeyPrefix: String {
        switch self {
            case .native: "native"
            case .webKit: "webkit"
        }
    }

    /// Source key for a given build number (e.g. `"native-825"`).
    public func sourceKey(build: Int) -> String {
        "\(sourceKeyPrefix)-\(build)"
    }
}
