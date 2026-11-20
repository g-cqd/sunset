import Foundation
import Testing

@testable import SunsetAppCore

/// ADR-0111: Sunset WebKit runs Sunset on the WebKit inside it. The owner, 2026-11-20: "the webkit version does not start":
/// a launcher ran Sunset as a second executable, whose team entitlements macOS does not honour outside the main one
/// (AMFI killed it). Sunset is the main executable and runs itself again, once, with the loader pointed at the app's
/// frameworks.
@Suite("Sunset WebKit points the loader at its own WebKit")
struct BundledWebKitTests {
    let bundle = "/Applications/Sunset WebKit.app"
    let info: [String: Any] = ["SunsetWebKitBase": "aa9b09cf"]

    @Test func `the bundled build runs itself again with the loader pointed at its frameworks`() throws {
        let wanted = try #require(
            BundledWebKit.environment(info: info, environment: ["HOME": "/Users/a"], bundle: bundle)
        )
        let frameworks = bundle + "/Contents/Frameworks"
        #expect(wanted["DYLD_FRAMEWORK_PATH"] == frameworks)
        #expect(wanted["DYLD_LIBRARY_PATH"] == frameworks)
        #expect(wanted["__XPC_DYLD_FRAMEWORK_PATH"] == frameworks)
        #expect(wanted["__XPC_DYLD_LIBRARY_PATH"] == frameworks)
        #expect(wanted["HOME"] == "/Users/a")
    }

    @Test func `only once: already pointed there, nothing to do`() throws {
        let first = try #require(BundledWebKit.environment(info: info, environment: [:], bundle: bundle))
        #expect(BundledWebKit.environment(info: info, environment: first, bundle: bundle) == nil)
    }

    @Test func `the native build never runs itself again`() {
        #expect(BundledWebKit.environment(info: [:], environment: [:], bundle: "/Applications/Sunset.app") == nil)
    }

    @Test func `nothing else is loaded into it`() throws {
        let wanted = try #require(
            BundledWebKit.environment(
                info: info,
                environment: [
                    "DYLD_INSERT_LIBRARIES": "/tmp/evil.dylib", "__XPC_DYLD_INSERT_LIBRARIES": "/tmp/evil.dylib"
                ],
                bundle: bundle
            )
        )
        #expect(wanted["DYLD_INSERT_LIBRARIES"] == nil)
        #expect(wanted["__XPC_DYLD_INSERT_LIBRARIES"] == nil)
    }
}
