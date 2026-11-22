import Foundation
import SunsetConfig
import Testing

@testable import SunsetAppCore

/// A terminal's link to a file: programs are shown in the Finder, not run, unless the setting says otherwise (ADR-0118;
/// the outside audit's LOW-05).
@Suite("Terminal file links") struct FileLinkTargetTests {
    private func folder() throws -> URL {
        let made = FileManager.default.temporaryDirectory.appending(path: "sunset-links-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: made, withIntermediateDirectories: true)
        return made
    }

    @Test func `apps, scripts, executables and installers are programs; documents and folders are not`() throws {
        let place = try folder()
        defer { try? FileManager.default.removeItem(at: place) }
        func file(_ name: String, executable: Bool = false) throws -> URL {
            let url = place.appending(path: name)
            try Data("echo hi\n".utf8).write(to: url)
            if executable { try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path) }
            return url
        }
        let app = place.appending(path: "Thing.app")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let folder = place.appending(path: "plain")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let disguised = place.appending(path: "notes.txt.link")
        try FileManager.default.createSymbolicLink(at: disguised, withDestinationURL: try file("run.command"))
        for program in [
            app, try file("run.command"), try file("tool", executable: true), try file("Setup.pkg"), disguised
        ] {
            #expect(FileLinkTarget.isProgram(program), "\(program.lastPathComponent)")
        }
        for document in [try file("notes.txt"), try file("photo.png"), folder] {
            #expect(!FileLinkTarget.isProgram(document), "\(document.lastPathComponent)")
        }
    }

    @Test func `the setting: programs shown by default; everything opened, or everything shown`() {
        typealias Links = Configuration.Terminal.FileLinks
        #expect(Configuration.Terminal().fileLinks == .revealPrograms)
        #expect(Links.revealPrograms.reveals(program: true) && !Links.revealPrograms.reveals(program: false))
        #expect(!Links.open.reveals(program: true) && Links.reveal.reveals(program: false))
    }
}
