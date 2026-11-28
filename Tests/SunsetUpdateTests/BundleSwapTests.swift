import Foundation
import SunsetUpdate
import Testing

/// The staged bundle takes the running one's place in one step (ADR-0122).
struct BundleSwapTests {
    @Test func swapsTheTwo() throws {
        try UpdatePackageTests.inFolder { folder in
            let running = folder.appending(path: "Sunset.app")
            let staging = folder.appending(path: ".Sunset-update.app")
            for (url, text) in [(running, "old"), (staging, "new")] {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                try Data(text.utf8).write(to: url.appending(path: "build"))
            }
            try BundleSwap.swap(running: running, staging: staging)
            let former = staging
            #expect(try String(contentsOf: running.appending(path: "build"), encoding: .utf8) == "new")
            #expect(try String(contentsOf: former.appending(path: "build"), encoding: .utf8) == "old")
        }
    }

    @Test func refusesWhenThereIsNothingToSwapWith() throws {
        try UpdatePackageTests.inFolder { folder in
            let running = folder.appending(path: "Sunset.app")
            try FileManager.default.createDirectory(at: running, withIntermediateDirectories: true)
            #expect(throws: BundleSwap.Failure.refused(ENOENT)) {
                try BundleSwap.swap(running: running, staging: folder.appending(path: "missing.app"))
            }
        }
    }

    /// What the person is told: the system's words, and where macOS refused, what to do (the owner, 2026-11-28: from
    /// /Applications the update did not go in, and nothing said why).
    @Test func saysWhyAndWhatToDo() {
        let missing = BundleSwap.Failure.refused(ENOENT).localizedDescription
        #expect(missing.contains("No such file or directory") && !missing.contains("App Management"))
        for denied in [EPERM, EACCES] {
            #expect(BundleSwap.Failure.refused(denied).localizedDescription.contains("App Management"))
        }
    }
}
