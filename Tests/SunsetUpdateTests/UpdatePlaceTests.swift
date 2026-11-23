import Foundation
import SunsetUpdate
import Testing

/// Where an update's package is, and where an app may update itself (roadmap 0122 D).
struct UpdatePlaceTests {
    @Test func namesThePackageFromTheRunningBuild() throws {
        let feed = """
            [{"tag_name": "v0.1.0-alpha.12", "name": "x", "draft": false, "prerelease": true, "body": "",
              "assets": [
                {"name": "Sunset-v0.1.0-alpha.12-build790-macos-arm64.zip", "size": 9,
                 "browser_download_url": "https://github.com/a/b/releases/download/t/z.zip"},
                {"name": "Sunset-v0.1.0-alpha.12-build790-from-build786-macos-arm64.update", "size": 3,
                 "browser_download_url": "https://github.com/a/b/releases/download/t/p.update"}]}]
            """
        let release = try #require(try ReleaseFeed.decode(Data(feed.utf8)).first)
        #expect(release.build == 790)
        #expect(release.package(for: .native, from: 786, architecture: "arm64")?.size == 3)
        #expect(release.package(for: .native, from: 781, architecture: "arm64") == nil)
        #expect(release.package(for: .webKit, from: 786, architecture: "arm64") == nil)
        #expect(
            PublishedRelease.packageName(flavour: .webKit, tag: "v1.0.0", to: 9, from: 8, architecture: "arm64")
                == "Sunset-WebKit-v1.0.0-build9-from-build8-macos-arm64.update"
        )
    }

    @Test func updatesOnlyASignedAppInAnApplicationsFolderItCanWrite() {
        let path = "/Users/a/Applications/Sunset.app"
        #expect(UpdatePlace.refusal(path: path, team: "T", writable: true) == nil)
        #expect(UpdatePlace.refusal(path: "/Applications/Sunset.app", team: "T", writable: true) == nil)
        #expect(UpdatePlace.refusal(path: path, team: nil, writable: true) == .unsigned)
        #expect(UpdatePlace.refusal(path: path, team: "T", writable: false) == .readOnly)
        #expect(
            UpdatePlace.refusal(path: "/tmp/x/.build/app-exp/Sunset.app", team: "T", writable: true) == .notInstalled
        )
        let translocated = "/private/var/folders/x/T/AppTranslocation/AB/d/Sunset.app"
        #expect(UpdatePlace.refusal(path: translocated, team: "T", writable: true) == .translocated)
    }
}
