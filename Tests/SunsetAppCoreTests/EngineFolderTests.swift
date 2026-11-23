import Testing

@testable import SunsetAppCore

/// The engine beside the app (roadmap 0113, ADR-0124): which WebKit the process runs on, from the images loaded; a
/// process with parts of both (an engine half-installed) is to be run again without it.
struct EngineFolderTests {
    static let app = "/Applications/Sunset.app"
    static let engine = "/Applications/SunsetEngine/Frameworks"
    static let system = "/System/Library/Frameworks"

    static func images(_ parts: [(String, String)]) -> [String] {
        ["/usr/lib/libSystem.B.dylib", app + "/Contents/MacOS/Sunset"]
            + parts.map { folder, name in "\(folder)/\(name).framework/Versions/A/\(name)" }
    }

    @Test func `the system's, the engine's, or a mix of the two`() {
        let both = ["WebKit", "WebCore", "JavaScriptCore"]
        #expect(
            EngineFolder.running(images: Self.images(both.map { (Self.system, $0) }), engine: Self.engine) == .system
        )
        #expect(
            EngineFolder.running(images: Self.images(both.map { (Self.engine, $0) }), engine: Self.engine) == .engine
        )
        let mixed = Self.images([(Self.engine, "WebKit"), (Self.engine, "JavaScriptCore"), (Self.system, "WebCore")])
        #expect(EngineFolder.running(images: mixed, engine: Self.engine) == .mixed("WebCore"))
    }

    @Test func `the folder is beside the app, and set aside under another name`() {
        #expect(EngineFolder.folder(app: Self.app) == "/Applications/SunsetEngine")
        #expect(EngineFolder.frameworks(app: Self.app) == Self.engine)
        #expect(EngineFolder.setAside(app: Self.app) == "/Applications/SunsetEngine (set aside)")
    }
}
