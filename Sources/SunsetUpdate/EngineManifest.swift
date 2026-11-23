public import Foundation

/// What a `SunsetEngine` folder is (roadmap 0113, ADR-0124): its build (the release's, which orders engines), the WebKit
/// base it was built from, and that base's date, read from its WebKit's own Info.plist, which its signature covers: an
/// older engine cannot say it is newer.
public struct EngineManifest: Equatable, Sendable {
    public let build: Int
    public let base: String
    public let baseDate: String?

    public init(build: Int, base: String, baseDate: String? = nil) {
        self.build = build
        self.base = base
        self.baseDate = baseDate
    }

    /// WebKit's Info.plist in an engine folder.
    static let place = "Frameworks/WebKit.framework/Versions/A/Resources/Info.plist"

    /// The manifest of the engine folder at `folder`, nil when it has none (not an engine).
    public static func read(from folder: URL) -> Self? {
        guard let info = NSDictionary(contentsOf: folder.appending(path: place)),
            let build = info["SunsetEngineBuild"] as? Int, let base = info["SunsetWebKitBase"] as? String
        else { return nil }
        return Self(build: build, base: base, baseDate: info["SunsetWebKitBaseDate"] as? String)
    }

    /// Writes it where it is read (the release's scripts write it with PlistBuddy, before signing; tests with this).
    public func write(to folder: URL) throws {
        let url = folder.appending(path: Self.place)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var info = (NSDictionary(contentsOf: url) as? [String: Any]) ?? [:]
        info["SunsetEngineBuild"] = build
        info["SunsetWebKitBase"] = base
        info["SunsetWebKitBaseDate"] = baseDate
        try (info as NSDictionary).write(to: url)
    }
}
