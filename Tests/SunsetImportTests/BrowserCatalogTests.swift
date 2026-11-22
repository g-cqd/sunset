import Testing

@testable import SunsetImport

/// Which browsers there are to import from, by the folders they keep their data in.
@Suite("The browsers to import from")
struct BrowserCatalogTests {
    @Test func `the browsers whose folder exists, in the catalogue's order; each read as its kind`() {
        let present: Set<String> = [
            "/Users/someone/Library/Application Support/Firefox",
            "/Users/someone/Library/Application Support/Google/Chrome Canary",
            "/Users/someone/Library/Safari"
        ]
        let found = BrowserCatalog.installed(home: "/Users/someone") { present.contains($0) }
        #expect(found.map(\.name) == ["Safari", "Google Chrome Canary", "Firefox"])
        #expect(found.map(\.kind) == [.safari, .chromium, .firefox])
    }

    @Test func `the catalogue holds the common ones, each name once`() {
        let names = BrowserCatalog.known.map(\.name)
        for name in [
            "Safari", "Google Chrome", "Arc", "Brave", "Microsoft Edge", "Vivaldi", "Opera", "Chromium", "Firefox",
            "Zen"
        ] {
            #expect(names.contains(name), "\(name)")
        }
        #expect(Set(names).count == names.count)
    }
}
