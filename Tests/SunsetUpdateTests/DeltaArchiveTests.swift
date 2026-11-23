import Foundation
import SunsetUpdate
import Testing

/// Single-archive range-addressed incremental format (`SSDLTA2`, ADR-0125): one archive per flavour holding a compressed
/// TOC at offset 0 and one contiguous byte range per supported source build (capped at K, with a size cutoff and full-file
/// fallback when a delta is not smaller).
struct DeltaArchiveTests {
    @Test func buildsMultiSourceArchiveAndAppliesViaRangeSlices() throws {
        try UpdatePackageTests.inFolder { folder in
            let code1 = BinaryDeltaTests.bytes(50_000, seed: 21)
            let code2 = BinaryDeltaTests.edited(code1)
            let code3 = BinaryDeltaTests.edited(code2)
            let b1 = folder.appending(path: "b1.app")
            let b2 = folder.appending(path: "b2.app")
            let target = folder.appending(path: "b3.app")
            try UpdatePackageTests.bundle(at: b1, executable: code1, resource: "r1", extra: false)
            try UpdatePackageTests.bundle(at: b2, executable: code2, resource: "r2", extra: false)
            try UpdatePackageTests.bundle(at: target, executable: code3, resource: "r3", extra: true)

            let built = try DeltaArchive.make(
                target: target,
                flavour: .native,
                toBuild: 3,
                sources: [
                    DeltaArchive.SourceInput(key: "native-2", bundle: b2),
                    DeltaArchive.SourceInput(key: "native-1", bundle: b1)
                ],
                maxSourceBytes: 1_000_000
            )
            #expect(built.toc.sources.keys.sorted() == ["native-1", "native-2"])
            #expect(built.data.prefix(8) == Data("SSDLTA2\0".utf8))

            // Simulate Request 1: read first 64 KiB (contains entire header + TOC), verify tocSHA256.
            let prefix = built.data.prefix(65_536)
            let header = try DeltaArchive.Header.decode(prefix)
            #expect(header.tocSHA256 == built.tocSHA256)
            let tocEnd = DeltaArchive.Header.size + header.tocLength
            let toc = try DeltaArchive.decodeTOC(
                Data(prefix[DeltaArchive.Header.size ..< tocEnd]),
                expectedSHA256: built.tocSHA256
            )

            // Simulate Request 2 for each source: fetch ONLY its single contiguous byte range, then stage.
            for (key, sourceBundle) in [("native-1", b1), ("native-2", b2)] {
                let plan = try #require(toc.sources[key])
                #expect(try DeltaArchive.preflight(plan: plan, running: sourceBundle))
                let fileStart = tocEnd + plan.rangeOffset
                let slice = built.data.subdata(in: fileStart ..< (fileStart + plan.rangeLength))
                let staging = folder.appending(path: "staged-\(key).app")
                try DeltaArchive.stage(toc: toc, plan: plan, payload: slice, running: sourceBundle, staging: staging)
                #expect(try BundleManifest.read(bundle: staging) == BundleManifest.read(bundle: target))
            }
        }
    }

    @Test func dropsSourceExceedingSizeCutoff() throws {
        try UpdatePackageTests.inFolder { folder in
            let old = folder.appending(path: "old.app")
            let new = folder.appending(path: "new.app")
            try UpdatePackageTests.bundle(
                at: old,
                executable: BinaryDeltaTests.bytes(20_000, seed: 1),
                resource: "a",
                extra: false
            )
            try UpdatePackageTests.bundle(
                at: new,
                executable: BinaryDeltaTests.bytes(20_000, seed: 2),
                resource: "b",
                extra: true
            )
            let built = try DeltaArchive.make(
                target: new,
                flavour: .native,
                toBuild: 2,
                sources: [DeltaArchive.SourceInput(key: "native-1", bundle: old)],
                maxSourceBytes: 100
            )
            #expect(built.toc.sources.isEmpty)
        }
    }

    @Test func rejectsDuplicatePathsAndEscapingSymlinkTargets() {
        #expect(BundleEntry.link("Contents/Frameworks/K.framework/Versions/Current", target: "A").hasSafeTarget)
        #expect(!BundleEntry.link("Contents/escape", target: "/etc/passwd").hasSafeTarget)
        #expect(!BundleEntry.link("Contents/escape", target: "../../../etc/passwd").hasSafeTarget)
        #expect(!BundleEntry.link("Contents/empty", target: "").hasSafeTarget)
    }

    @Test func allowsOnlyGitHubHttpsHostsUnlessOverridden() throws {
        let ok1 = try #require(URL(string: "https://github.com/g-cqd/sunset/releases/download/v1/a.zip"))
        let ok2 = try #require(URL(string: "https://release-assets.githubusercontent.com/blob/123"))
        let ok3 = try #require(URL(string: "https://objects.githubusercontent.com/blob/123"))
        let ok4 = try #require(URL(string: "https://api.github.com/repos/g-cqd/sunset/releases"))
        let badHttp = try #require(URL(string: "http://github.com/g-cqd/sunset/releases/download/v1/a.zip"))
        let badHost = try #require(URL(string: "https://evil.example/a.zip"))
        let badRepo = try #require(URL(string: "https://github.com/other/repo/releases/download/v1/a.zip"))
        #expect(UpdateURLPolicy.isAllowed(ok1))
        #expect(UpdateURLPolicy.isAllowed(ok2))
        #expect(UpdateURLPolicy.isAllowed(ok3))
        #expect(UpdateURLPolicy.isAllowed(ok4))
        #expect(!UpdateURLPolicy.isAllowed(badHttp))
        #expect(!UpdateURLPolicy.isAllowed(badHost))
        #expect(!UpdateURLPolicy.isAllowed(badRepo))
    }
}
