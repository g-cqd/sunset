/// The WebKit engine as a component beside the app (roadmap 0113, ADR-0124): `SunsetEngine/Frameworks` next to
/// `Sunset.app`, which the executables' loader path names after the app's own Frameworks. Off, or set aside, it has another
/// name, and the system's WebKit is used.
package enum EngineFolder {
    /// The engine's frameworks the check looks at: a process mixes WebKits when some of these come from the engine and
    /// some from elsewhere.
    static let parts = ["WebKit", "WebCore", "JavaScriptCore", "WebKitLegacy", "WebGPU"]

    package enum Running: Equatable, Sendable {
        case system
        case engine
        /// Some of the engine's frameworks loaded from it, `part` from elsewhere (a half-installed engine).
        case mixed(String)
    }

    /// `SunsetEngine` beside the app at `app`.
    package static func folder(app: String) -> String {
        parent(of: app) + "/SunsetEngine"
    }

    package static func frameworks(app: String) -> String {
        folder(app: app) + "/Frameworks"
    }

    /// Where an engine that cannot be used goes, so that the next start runs on the system's.
    package static func setAside(app: String) -> String {
        folder(app: app) + " (set aside)"
    }

    /// Which WebKit the process runs on, from `images` (every image loaded).
    package static func running(images: [String], engine: String) -> Running {
        let loaded = parts.compactMap { part -> (part: String, ours: Bool)? in
            images.first { $0.contains("/\(part).framework/") }.map { (part, $0.hasPrefix(engine + "/")) }
        }
        guard loaded.contains(where: \.ours) else { return .system }
        if let other = loaded.first(where: { !$0.ours }) { return .mixed(other.part) }
        return .engine
    }

    private static func parent(of path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else { return "." }
        return String(path[..<slash])
    }
}
