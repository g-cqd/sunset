import Foundation
import Testing

@testable import SunsetAppCore

/// A terminal's link to a file that names another: a Finder alias opens what it names (Launch Services resolves it, so an
/// alias called `notes.txt` to an app starts the app), and macOS's own list of the kinds that run code
/// (`LSRiskCategoryUnsafeExecutable` in CoreTypes.bundle) is wider than the downloads' list (ADR-0118).
@Suite("Terminal file links: aliases and macOS's risky kinds") struct FileLinkIndirectionTests {
    private let place: URL

    init() throws {
        place = FileManager.default.temporaryDirectory.appending(path: "sunset-link-kinds-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: place, withIntermediateDirectories: true)
    }

    private func file(_ name: String) throws -> URL {
        let url = place.appending(path: name)
        try Data("echo hi\n".utf8).write(to: url)
        return url
    }

    /// A Finder alias file to `target`, as the Finder makes one.
    private func alias(_ name: String, to target: URL) throws -> URL {
        let url = place.appending(path: name)
        let data = try target.bookmarkData(options: .suitableForBookmarkFile)
        try URL.writeBookmarkData(data, to: url)
        return url
    }

    @Test func `an alias is judged by what it names, whatever it is called`() throws {
        defer { try? FileManager.default.removeItem(at: place) }
        let app = place.appending(path: "Thing.app")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let toApp = try alias("notes.txt", to: app)
        let toScript = try alias("readme.md", to: try file("run.command"))
        #expect(FileLinkTarget.isProgram(toApp))
        #expect(FileLinkTarget.isProgram(toScript))

        let notes = try file("real.txt")
        let toNotes = try alias("notes-alias.txt", to: notes)
        #expect(!FileLinkTarget.isProgram(toNotes))
        #expect(FileLinkTarget.target(of: toNotes)?.standardizedFileURL.path == notes.resolvingSymlinksInPath().path)

        // A symbolic link to an alias to a script.
        let chained = place.appending(path: "chain.txt")
        try FileManager.default.createSymbolicLink(at: chained, withDestinationURL: toScript)
        #expect(FileLinkTarget.isProgram(chained))
    }

    @Test func `an alias that names nothing any more is shown, not opened`() throws {
        defer { try? FileManager.default.removeItem(at: place) }
        let gone = try file("gone.txt")
        let dangling = try alias("dangling.txt", to: gone)
        try FileManager.default.removeItem(at: gone)
        #expect(FileLinkTarget.target(of: dangling) == nil)
        #expect(FileLinkTarget.isProgram(dangling))
    }

    @Test(arguments: [
        "page.webarchive", "shell.term", "Thing.service", "Help.help", "Main.nib", "launch.jnlp", "Main.class",
        "effect.qtz", "App.ipa", "Setup.mpkg", "where.fileloc", "where.inetloc", "Input.inputplugin", "flow.wflow"
    ])
    func `macOS's risky kinds are programs`(name: String) throws {
        defer { try? FileManager.default.removeItem(at: place) }
        #expect(FileLinkTarget.isProgram(try file(name)))
    }

    @Test(arguments: ["notes.txt", "README.md", "photo.png", "page.html", "archive.zip", "disk.dmg", "data.json"])
    func `documents, archives and disk images are not`(name: String) throws {
        defer { try? FileManager.default.removeItem(at: place) }
        #expect(!FileLinkTarget.isProgram(try file(name)))
    }
}
