import Foundation
import SunsetUpdate
import Testing

/// What may be put in place as the engine (ADR-0124): every piece of code in its Frameworks signed as asked, nothing
/// else there, its manifest present and later than the one it replaces.
struct EngineCheckTests {
    @Test
    func `refuses an engine with no manifest, an older or equal build, unsigned code or something else in Frameworks`()
        throws
    {
        try UpdatePackageTests.inFolder { folder in
            let engine = folder.appending(path: "SunsetEngine")
            try FileManager.default.createDirectory(
                at: engine.appending(path: "Frameworks"),
                withIntermediateDirectories: true
            )
            #expect(throws: EngineCheck.Failure.noManifest) {
                try EngineCheck.check(engine, requirement: "anchor apple", after: 0)
            }
            try EngineInstallTests.engine(at: engine, build: 820, base: "b", code: "x")
            #expect(throws: EngineCheck.Failure.notLater(installed: 820, staged: 820)) {
                try EngineCheck.check(engine, requirement: "anchor apple", after: 820)
            }
            #expect(throws: EngineCheck.Failure.refused("WebKit.framework")) {
                try EngineCheck.check(engine, requirement: "anchor apple", after: 810)
            }
            try Data().write(to: engine.appending(path: "Frameworks/notes.txt"))
            #expect(throws: EngineCheck.Failure.unexpected("notes.txt")) {
                try EngineCheck.check(engine, requirement: "anchor apple", after: 810)
            }
        }
    }
}
