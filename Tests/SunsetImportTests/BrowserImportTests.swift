import Foundation
import Testing

@testable import SunsetImport

/// A browser's profiles and what each holds, read from its folder (roadmap 0111 G).
@Suite("Importing from a browser's folder")
struct BrowserImportTests {
    private func home() throws -> URL {
        let home = FileManager.default.temporaryDirectory.appending(path: "home-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        return home
    }

    private func write(_ text: String, _ path: String, in home: URL) throws {
        let file = home.appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file)
    }

    private func browser(_ name: String) throws -> Browser {
        try #require(BrowserCatalog.known.first { $0.name == name })
    }

    @Test func `Chromium: its profiles, and a profile's bookmarks and extensions`() throws {
        let home = try home()
        defer { try? FileManager.default.removeItem(at: home) }
        let root = "Library/Application Support/BraveSoftware/Brave-Browser/"
        try write(#"{"profile": {"info_cache": {"Default": {"name": "Me"}}}}"#, root + "Local State", in: home)
        try write(
            #"{"roots": {"bookmark_bar": {"type": "folder", "name": "Bar", "children": [{"type": "url", "name": "A", "url": "https://a.example/"}]}}}"#,
            root + "Default/Bookmarks",
            in: home
        )
        try write(
            #"{"name": "Blocker"}"#,
            root + "Default/Extensions/cjpalhdlnbpafiamejdnhcphjbkeiagm/1.0_0/manifest.json",
            in: home
        )
        let brave = try browser("Brave")
        let profiles = try BrowserImport.profiles(of: brave, home: home.path)
        #expect(profiles == [BrowserProfile(folder: "Default", name: "Me")])
        let read = try BrowserImport.read(profiles[0], of: brave, home: home.path)
        #expect(read.bookmarks == [.link(BookmarkLink(title: "A", address: "https://a.example/"))])
        #expect(read.extensions.map(\.name) == ["Blocker"])
    }

    @Test func `a Chromium folder without Local State is one profile: Opera's`() throws {
        let home = try home()
        defer { try? FileManager.default.removeItem(at: home) }
        let root = "Library/Application Support/com.operasoftware.Opera/"
        try write(#"{"roots": {}}"#, root + "Bookmarks", in: home)
        let opera = try browser("Opera")
        let profiles = try BrowserImport.profiles(of: opera, home: home.path)
        #expect(profiles == [BrowserProfile(folder: "", name: "Opera")])
        #expect(try BrowserImport.read(profiles[0], of: opera, home: home.path) == ImportedProfile())
    }

    @Test func `Firefox: its profiles; a profile's extensions and containers, no places database no bookmarks`() throws
    {
        let home = try home()
        defer { try? FileManager.default.removeItem(at: home) }
        let root = "Library/Application Support/Firefox/"
        try write(
            "[Profile0]\nName=default-release\nIsRelative=1\nPath=Profiles/x.default-release\n",
            root + "profiles.ini",
            in: home
        )
        try write(
            #"{"addons": [{"id": "a@b", "type": "extension", "location": "app-profile", "defaultLocale": {"name": "Ext"}}]}"#,
            root + "Profiles/x.default-release/extensions.json",
            in: home
        )
        try write(
            #"{"identities": [{"public": true, "name": "Garden"}]}"#,
            root + "Profiles/x.default-release/containers.json",
            in: home
        )
        let firefox = try browser("Firefox")
        let profiles = try BrowserImport.profiles(of: firefox, home: home.path)
        #expect(profiles == [BrowserProfile(folder: "Profiles/x.default-release", name: "default-release")])
        let read = try BrowserImport.read(profiles[0], of: firefox, home: home.path)
        #expect(read.bookmarks.isEmpty)
        #expect(read.extensions.map(\.name) == ["Ext"])
        #expect(read.containers == [BrowserContainer(name: "Garden")])
    }

    @Test func `a file macOS refuses is named as needing access`() throws {
        let home = try home()
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o644],
                ofItemAtPath: home.appending(path: "Library/Safari/Bookmarks.plist").path
            )
            try? FileManager.default.removeItem(at: home)
        }
        try write("x", "Library/Safari/Bookmarks.plist", in: home)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0],
            ofItemAtPath: home.appending(path: "Library/Safari/Bookmarks.plist").path
        )
        let safari = try browser("Safari")
        let profiles = try BrowserImport.profiles(of: safari, home: home.path)
        #expect(profiles == [BrowserProfile(folder: "", name: "Safari")])
        #expect(throws: BrowserImport.Failure.needsAccess(home.appending(path: "Library/Safari/Bookmarks.plist").path))
        {
            try BrowserImport.read(profiles[0], of: safari, home: home.path)
        }
    }
}
