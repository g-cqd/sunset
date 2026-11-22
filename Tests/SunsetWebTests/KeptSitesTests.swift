import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The sites whose data is kept, chosen or signed in to; filled once with the sites holding cookies.
@MainActor
@Suite("The sites kept") struct KeptSitesTests {
    @Test func `a site kept keeps its subdomains, and is let go`() {
        let sites = KeptSites()
        sites.set(true, for: "example.org")
        #expect(sites.keeps("example.org") && sites.keeps("app.example.org") && !sites.keeps("other.org"))
        #expect(sites.hosts == ["example.org"])
        sites.set(false, for: "example.org")
        #expect(!sites.keeps("example.org") && sites.hosts.isEmpty)
    }

    @Test func `it is filled with the sites holding cookies once, never again`() {
        let sites = KeptSites()
        #expect(sites.seedOnce(with: ["a.example", "b.example"]))
        #expect(sites.hosts == ["a.example", "b.example"])
        sites.set(false, for: "a.example")
        #expect(!sites.seedOnce(with: ["a.example", "c.example"]))
        #expect(sites.hosts == ["b.example"], "a site let go is not put back")
    }

    /// A test copy shares WebKit's stores and the defaults with the person's Sunset, not its sealed store: the mark that
    /// the list was filled lives with the list, never in the defaults (2026-11-18).
    @Test func `the mark that it was filled lives with the list`() throws {
        let path = FileManager.default.temporaryDirectory.appending(path: "kept-\(UUID().uuidString).sqlite").path
        defer { try? FileManager.default.removeItem(atPath: path) }
        let sites = KeptSites(
            table: try TestState.table("kept", at: path),
            marks: try TestState.table("kept-marks", at: path)
        )
        #expect(sites.seedOnce(with: ["a.example"]))
        let again = KeptSites(
            table: try TestState.table("kept", at: path),
            marks: try TestState.table("kept-marks", at: path)
        )
        #expect(!again.seedOnce(with: ["b.example"]) && again.hosts == ["a.example"])
        let elsewhere = KeptSites()
        #expect(elsewhere.seedOnce(with: ["c.example"]), "another store is filled on its own")
    }
}
