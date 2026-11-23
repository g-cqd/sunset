import Foundation
import SunsetUpdate
import Testing

/// The whole way of an update, from a feed to the app swapped, on files (roadmap 0122 D): the package from the running
/// build when there is one and it applies, the archive otherwise; nothing replaces the app that the trust check refuses.
struct UpdateInstallerTests {
    /// Old and new bundles, the new one zipped, its package from build 1, and a feed naming them by file addresses.
    struct Published {
        let old: URL
        let new: URL
        let offer: UpdateOffer
    }

    static func publish(in folder: URL, package: Bool, brokenPackage: Bool = false) throws -> Published {
        let (old, new) = try UpdatePackageTests.pair(in: folder)
        for (app, build) in [(old, "1"), (new, "2")] {
            try (["CFBundleVersion": build] as NSDictionary).write(to: app.appending(path: "Contents/Info.plist"))
        }
        let assets = folder.appending(path: "assets")
        try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
        let archive = assets.appending(path: "Sunset-v2-build2-macos-arm64.zip")
        let ditto = Process()
        ditto.executableURL = URL(filePath: "/usr/bin/ditto")
        ditto.arguments = ["-c", "-k", "--keepParent", new.path, archive.path]
        try ditto.run()
        ditto.waitUntilExit()
        var listed = [archive]
        if package {
            let file = assets.appending(path: "Sunset-v2-build2-from-build1-macos-arm64.update")
            var data = try UpdatePackage.make(old: old, new: new, from: 1, to: 2)
            if brokenPackage { data[data.count - 1] ^= 0xFF }
            try data.write(to: file)
            listed.append(file)
        }
        let json = listed.map { url in
            "{\"name\": \"\(url.lastPathComponent)\", \"size\": 1, \"browser_download_url\": \"\(url.absoluteString)\"}"
        }
        let feed = """
            [{"tag_name": "v2", "name": "Two", "draft": false, "prerelease": false, "body": "New things",
              "assets": [\(json.joined(separator: ","))]}]
            """
        let releases = try ReleaseFeed.decode(Data(feed.utf8))
        let offer = try #require(
            UpdateChoice.offer(in: releases, flavour: .native, architecture: "arm64", running: 1, prereleases: false)
        )
        return Published(old: old, new: new, offer: offer)
    }

    /// Fetches a file address by copying it, and records what it fetched.
    final class Fetched: @unchecked Sendable {
        var names: [String] = []
        let lock = NSLock()

        func installer(trust: @escaping @Sendable (URL) throws -> Void = { _ in }) -> UpdateInstaller {
            UpdateInstaller(
                fetch: { [self] url in
                    lock.withLock { names.append(url.lastPathComponent) }
                    let copy = FileManager.default.temporaryDirectory.appending(path: "fetched-\(UUID().uuidString)")
                    try FileManager.default.copyItem(at: url, to: copy)
                    return copy
                },
                trust: trust
            )
        }
    }

    @Test func takesThePackageFromTheRunningBuildAndSwapsTheAppIn() async throws {
        try await UpdatePackageTests.inFolderAsync { folder in
            let published = try Self.publish(in: folder, package: true)
            let fetched = Fetched()
            let staging = folder.appending(path: ".old-update.app")
            let running = RunningBundle(bundle: published.old, build: 1, flavour: .native, architecture: "arm64")
            try await fetched.installer().stage(published.offer, running: running, staging: staging)
            #expect(fetched.names == ["Sunset-v2-build2-from-build1-macos-arm64.update"])
            try BundleSwap.swap(running: published.old, staging: staging)
            #expect(try BundleManifest.read(bundle: published.old) == BundleManifest.read(bundle: published.new))
        }
    }

    @Test func takesTheArchiveWhenThereIsNoPackageOrItDoesNotApply() async throws {
        for broken in [false, true] {
            try await UpdatePackageTests.inFolderAsync { folder in
                let published = try Self.publish(in: folder, package: broken, brokenPackage: broken)
                let fetched = Fetched()
                let staging = folder.appending(path: ".old-update.app")
                let running = RunningBundle(bundle: published.old, build: 1, flavour: .native, architecture: "arm64")
                try await fetched.installer().stage(published.offer, running: running, staging: staging)
                #expect(fetched.names.last == "Sunset-v2-build2-macos-arm64.zip")
                #expect(try BundleManifest.read(bundle: staging) == BundleManifest.read(bundle: published.new))
            }
        }
    }

    @Test func leavesNothingStagedWhenTheTrustCheckRefuses() async throws {
        try await UpdatePackageTests.inFolderAsync { folder in
            let published = try Self.publish(in: folder, package: true)
            let staging = folder.appending(path: ".old-update.app")
            let running = RunningBundle(bundle: published.old, build: 1, flavour: .native, architecture: "arm64")
            let refusing = Fetched().installer { _ in throw SignatureCheck.Failure.refused(-1) }
            await #expect(throws: SignatureCheck.Failure.refused(-1)) {
                try await refusing.stage(published.offer, running: running, staging: staging)
            }
            #expect(!FileManager.default.fileExists(atPath: staging.path))
        }
    }
}
