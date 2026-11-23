import Foundation
import SunsetUpdate
import Testing

/// The WebKit engine as a component (roadmap 0113 C, ADR-0124): published as `SunsetEngine-<tag>-build<N>-macos-<arch>.zip`
/// holding one `SunsetEngine` folder (its `Frameworks` and `engine.plist`); offered when later than the one installed;
/// staged beside the app and checked whole; put in place by one swap.
struct EngineInstallTests {
    /// An engine folder: two "frameworks" and its manifest.
    static func engine(at url: URL, build: Int, base: String, code: String) throws {
        let frameworks = url.appending(path: "Frameworks/WebKit.framework/Versions/A")
        try FileManager.default.createDirectory(at: frameworks, withIntermediateDirectories: true)
        try Data(code.utf8).write(to: frameworks.appending(path: "WebKit"))
        try Data("rtc \(code)".utf8).write(to: url.appending(path: "Frameworks/libwebrtc.dylib"))
        try EngineManifest(build: build, base: base).write(to: url)
    }

    @Test func `the manifest says the engine's build and WebKit base, and reads back`() throws {
        try UpdatePackageTests.inFolder { folder in
            try Self.engine(at: folder.appending(path: "SunsetEngine"), build: 820, base: "944f9ff6", code: "a")
            let read = try #require(EngineManifest.read(from: folder.appending(path: "SunsetEngine")))
            #expect(read == EngineManifest(build: 820, base: "944f9ff6"))
            #expect(EngineManifest.read(from: folder) == nil)
        }
    }

    @Test func `an engine release is found by its name and offered over an older one, or when none is installed`()
        throws
    {
        let feed = """
            [{"tag_name": "v0.1.0-alpha.12", "name": "x", "draft": false, "prerelease": true, "body": "Engine notes",
              "assets": [{"name": "SunsetEngine-v0.1.0-alpha.12-build820-macos-arm64.zip", "size": 9,
                          "browser_download_url": "https://github.com/a/b/releases/download/t/e.zip"},
                         {"name": "Sunset-v0.1.0-alpha.12-build820-macos-arm64.zip", "size": 8,
                          "browser_download_url": "https://github.com/a/b/releases/download/t/s.zip"}]}]
            """
        let releases = try ReleaseFeed.decode(Data(feed.utf8))
        let offer = UpdateChoice.offer(
            in: releases,
            flavour: .engine,
            architecture: "arm64",
            running: 0,
            prereleases: true
        )
        #expect(offer?.archive.name == "SunsetEngine-v0.1.0-alpha.12-build820-macos-arm64.zip")
        #expect(
            UpdateChoice.offer(in: releases, flavour: .engine, architecture: "arm64", running: 820, prereleases: true)
                == nil
        )
    }

    @Test func `staged beside the app from its archive, checked whole, then swapped in place of the one before`()
        async throws
    {
        try await UpdatePackageTests.inFolderAsync { folder in
            let built = folder.appending(path: "built/SunsetEngine")
            try Self.engine(at: built, build: 820, base: "new", code: "new")
            let archive = folder.appending(path: "SunsetEngine-v2-build820-macos-arm64.zip")
            let ditto = Process()
            ditto.executableURL = URL(filePath: "/usr/bin/ditto")
            ditto.arguments = ["-c", "-k", "--keepParent", built.path, archive.path]
            try ditto.run()
            ditto.waitUntilExit()
            let installed = folder.appending(path: "SunsetEngine")
            try Self.engine(at: installed, build: 810, base: "old", code: "old")
            let release = PublishedRelease(
                tag: "v2",
                title: "Two",
                build: 820,
                prerelease: false,
                notes: "",
                published: nil,
                assets: [ReleaseAsset(name: archive.lastPathComponent, size: 1, url: archive)]
            )
            let offer = try #require(
                UpdateChoice.offer(
                    in: [release],
                    flavour: .engine,
                    architecture: "arm64",
                    running: 810,
                    prereleases: false
                )
            )
            let checked = Checked()
            let installer = UpdateInstallerTests.Fetched().installer { staged in checked.add(staged) }
            let staging = folder.appending(path: ".SunsetEngine-update")
            let running = RunningBundle(bundle: installed, build: 810, flavour: .engine, architecture: "arm64")
            try await installer.stage(offer, running: running, staging: staging)
            #expect(checked.all == [staging])
            #expect(EngineManifest.read(from: staging) == EngineManifest(build: 820, base: "new"))
            try BundleSwap.swap(running: installed, staging: staging)
            #expect(EngineManifest.read(from: installed)?.build == 820)
        }
    }

    final class Checked: @unchecked Sendable {
        private(set) var all: [URL] = []
        private let lock = NSLock()
        func add(_ url: URL) {
            lock.withLock { all.append(url) }
        }
    }
}
