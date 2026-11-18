import Foundation
import Testing

@testable import SunsetStorage

/// Roadmap 0051 G (the owner's extended audit, note n23): WebKit's folders and files beside Sunset's are its owner's only.
@Suite("WebKit's folders, the owner's only") struct WebKitFoldersTests {
    private func mode(_ url: URL) -> Int {
        ((try? FileManager.default.attributesOfItem(atPath: url.path))?[.posixPermissions] as? Int) ?? -1
    }

    @Test func `the caches, the website data and the cookie jar are made 0700 and 0600, what is missing left alone`()
        throws
    {
        let library = FileManager.default.temporaryDirectory.appending(path: "sunset-webkit-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: library) }
        let id = "studio.example.app"
        let files = FileManager.default
        for folder in ["Caches/\(id)/WebKit", "WebKit/\(id)/WebsiteData", "HTTPStorages/\(id)"] {
            try files.createDirectory(
                at: library.appending(path: folder),
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o755]
            )
        }
        let jar = library.appending(path: "HTTPStorages/\(id).binarycookies")
        #expect(files.createFile(atPath: jar.path, contents: Data(), attributes: [.posixPermissions: 0o644]))
        let places = WebKitFolders.places(library: library, bundleID: id)
        #expect(places.folders.map(\.lastPathComponent) == [id, id, id])
        #expect(places.files == [jar])
        #expect(WebKitFolders.tighten(library: library, bundleID: id) == 4)
        for folder in places.folders { #expect(mode(folder) == 0o700, "\(folder.path)") }
        #expect(mode(jar) == 0o600)
        #expect(WebKitFolders.tighten(library: library, bundleID: id) == 0, "a second time changes nothing")
        #expect(WebKitFolders.tighten(library: library, bundleID: "missing.app") == 0)
    }
}
