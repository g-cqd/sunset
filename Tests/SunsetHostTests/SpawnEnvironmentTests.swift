import SunsetTestSupport
import Testing

@testable import SunsetHost

/// What the loader was told for Sunset itself (Sunset WebKit runs again with its frameworks in `DYLD_FRAMEWORK_PATH` and
/// `__XPC_DYLD_*`) is not passed to the programs of its terminals: each would load the app's frameworks, and any of them
/// could point another program's loader elsewhere (the outside audit's DYN-SEC-01, 2026-11-22). The rest of the
/// environment is passed as it was.
@Suite("Spawning: the loader's variables are not passed on") struct SpawnEnvironmentTests {
    @Test func `DYLD and __XPC_DYLD variables are dropped; others are kept`() throws {
        let session = try HeadlessSession(
            [
                "/bin/sh", "-c",
                "echo \"xpc=${__XPC_DYLD_FRAMEWORK_PATH-unset} lib=${__XPC_DYLD_LIBRARY_PATH-unset} kept=${SUNSET_KEPT-unset}\""
            ],
            environment: [
                "__XPC_DYLD_FRAMEWORK_PATH": "/tmp/frameworks", "__XPC_DYLD_LIBRARY_PATH": "/tmp/frameworks",
                "DYLD_FRAMEWORK_PATH": "/tmp/frameworks", "SUNSET_KEPT": "yes"
            ]
        )
        #expect(session.waitForExit())
        #expect(session.lines.contains("xpc=unset lib=unset kept=yes"), "\(session.lines.prefix(2))")
    }
}
