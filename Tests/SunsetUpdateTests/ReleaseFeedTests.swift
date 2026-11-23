import Foundation
import SunsetUpdate
import Testing

/// GitHub's releases list read into releases (roadmap 0122 B), from a list shaped as the API returns it.
struct ReleaseFeedTests {
    static func asset(_ name: String, size: Int = 10) -> String {
        """
        {"name": "\(name)", "size": \(size),
         "browser_download_url": "https://github.com/g-cqd/sunset/releases/download/x/\(name)"}
        """
    }

    static func release(_ number: Int, build: Int, draft: Bool = false, pre: Bool = true, webKit: Bool = true) -> String
    {
        let tag = "v0.1.0-alpha.\(number)"
        var assets = [asset("Sunset-\(tag)-build\(build)-macos-arm64.zip", size: 100 + number)]
        assets.append(asset("Sunset-\(tag)-build\(build)-macos-arm64.zip.sha256"))
        if webKit { assets.append(asset("Sunset-WebKit-\(tag)-build\(build)-macos-arm64.zip", size: 900)) }
        return """
            {"tag_name": "\(tag)", "name": "Sunset 0.1.0-alpha.\(number) (build \(build))", "draft": \(draft),
             "prerelease": \(pre), "body": "Notes of \(number)", "published_at": "2026-11-2\(number % 10)T06:58:18Z",
             "assets": [\(assets.joined(separator: ","))]}
            """
    }

    static func feed(_ releases: [String]) -> Data {
        Data("[\(releases.joined(separator: ","))]".utf8)
    }

    @Test func readsTagBuildNotesAndTheAssetsOfEachFlavour() throws {
        let releases = try ReleaseFeed.decode(Self.feed([Self.release(11, build: 786)]))
        #expect(releases.count == 1)
        let release = try #require(releases.first)
        #expect(release.tag == "v0.1.0-alpha.11")
        #expect(release.build == 786)
        #expect(release.notes == "Notes of 11")
        #expect(release.prerelease)
        let native = try #require(release.archive(for: .native, architecture: "arm64"))
        #expect(native.name == "Sunset-v0.1.0-alpha.11-build786-macos-arm64.zip")
        #expect(native.size == 111)
        #expect(native.url.host() == "github.com")
        let webKit = try #require(release.archive(for: .webKit, architecture: "arm64"))
        #expect(webKit.name == "Sunset-WebKit-v0.1.0-alpha.11-build786-macos-arm64.zip")
        #expect(release.archive(for: .native, architecture: "x86_64") == nil)
    }

    @Test func leavesOutDraftsAndReleasesWithoutABuild() throws {
        let bare = """
            {"tag_name": "v0.0.1", "name": "x", "draft": false, "prerelease": false, "body": null, "assets": []}
            """
        let releases = try ReleaseFeed.decode(Self.feed([Self.release(12, build: 790, draft: true), bare]))
        #expect(releases.isEmpty)
    }

    @Test func refusesWhatIsNotAList() {
        #expect(throws: DecodingError.self) { try ReleaseFeed.decode(Data("{\"message\": \"rate\"}".utf8)) }
    }
}
