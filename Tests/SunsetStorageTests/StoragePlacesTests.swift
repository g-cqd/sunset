import Testing

@testable import SunsetStorage

@Suite("Where each thing Sunset keeps is")
struct StoragePlacesTests {
    @Test func `by default everything is in Application Support, under one folder`() {
        let places = StoragePlaces(environment: [:], home: "/h/")
        #expect(places.directory == "/h/Library/Application Support/Sunset")
        #expect(places.session == "/h/Library/Application Support/Sunset/session.sealed")
        #expect(places.legacySession == "/h/Library/Application Support/Sunset/session.json")
        #expect(places.state == "/h/Library/Application Support/Sunset/state.sqlite")
        #expect(places.documents == "/h/Library/Application Support/Sunset/Documents")
        #expect(places.library == "/h/Library/Application Support/Sunset/library.sqlite")
    }

    @Test func `a named session file takes everything beside it; a named configuration too; empty names count as none`()
    {
        let named = StoragePlaces(environment: ["SUNSET_SESSION": "/x/s.json"], home: "/h")
        #expect(named.session == "/x/s.json" && named.directory == "/x" && named.state == "/x/state.sqlite")
        #expect(named.legacySession == nil)
        let test = StoragePlaces(environment: ["SUNSET_CONFIG": "/tmp/lk2/c.json"], home: "/h")
        #expect(test.session == "/tmp/lk2/session.sealed" && test.legacySession == "/tmp/lk2/session.json")
        #expect(test.documents == "/tmp/lk2/Documents")
        #expect(StoragePlaces(environment: ["SUNSET_CONFIG": "c.json"], home: "/h").session == "./session.sealed")
        let empty = StoragePlaces(environment: ["SUNSET_SESSION": "", "SUNSET_CONFIG": ""], home: "/h")
        #expect(empty == StoragePlaces(environment: [:], home: "/h"))
    }

    /// A build that is not the installed one (its identifier ends in `.dev`) started with nothing named must not read
    /// or write the person's session, nor ask for his keys (a test copy started on his session once, 2026-11-16).
    @Test
    func `a development build keeps its own folder and its own keys; a named setup is the same whatever the build`() {
        let installed = StoragePlaces(environment: [:], home: "/h", identifier: "studio.aemi.sunset")
        #expect(installed == StoragePlaces(environment: [:], home: "/h") && !installed.isDevelopment)
        #expect(installed.keyService == "studio.aemi.sunset.storage-key")
        #expect(installed.commandSealService == "studio.aemi.sunset.command-seal")
        let development = StoragePlaces(environment: [:], home: "/h", identifier: "studio.aemi.sunset.dev")
        #expect(development.isDevelopment && development.isDefault)
        #expect(development.directory == "/h/Library/Application Support/Sunset Dev")
        #expect(development.session == "/h/Library/Application Support/Sunset Dev/session.sealed")
        #expect(development.keyService == "studio.aemi.sunset.dev.storage-key")
        #expect(development.commandSealService == "studio.aemi.sunset.dev.command-seal")
        let named = ["SUNSET_CONFIG": "/t/config.json"]
        let test = StoragePlaces(environment: named, home: "/h", identifier: "studio.aemi.sunset.dev")
        #expect(test.directory == "/t" && !test.isDefault)
        #expect(test.directory == StoragePlaces(environment: named, home: "/h").directory)
    }

    /// Sunset WebKit keeps Sunset's store and keys; its own from before are still found, to be merged once.
    @Test func `Sunset WebKit shares Sunset's places, and knows its own from before`() throws {
        let sunset = StoragePlaces(environment: [:], home: "/h", identifier: "studio.aemi.sunset")
        let webKit = StoragePlaces(environment: [:], home: "/h", identifier: "studio.aemi.sunset.webkit")
        #expect(webKit.directory == sunset.directory && webKit.keyService == sunset.keyService)
        #expect(webKit.commandSealService == sunset.commandSealService && webKit.variant == nil)
        let former = try #require(webKit.former)
        #expect(former.directory == "/h/Library/Application Support/Sunset Webkit")
        #expect(former.keyService == "studio.aemi.sunset.webkit.storage-key")
        #expect(sunset.former == nil)
        // The builds that keep the same store, each the other's (one at a time).
        #expect(StoragePlaces.sharers(of: "studio.aemi.sunset") == ["studio.aemi.sunset.webkit"])
        #expect(StoragePlaces.sharers(of: "studio.aemi.sunset.webkit") == ["studio.aemi.sunset"])
        #expect(StoragePlaces.sharers(of: "studio.aemi.sunset.lab").isEmpty)
        #expect(StoragePlaces.sharers(of: "studio.aemi.sunset.dev").isEmpty && StoragePlaces.sharers(of: nil).isEmpty)
        // Another variant keeps its own, as before.
        let lab = StoragePlaces(environment: [:], home: "/h", identifier: "studio.aemi.sunset.lab")
        #expect(
            lab.variant == "lab" && lab.directory == "/h/Library/Application Support/Sunset Lab" && lab.former == nil
        )
    }

    @Test func `the files of before the database are still found, to be imported`() {
        let places = StoragePlaces(environment: ["SUNSET_CONFIG": "/t/config.json"], home: "/h")
        #expect(places.legacyZoom == "/t/site-zoom.json" && places.legacyHistory == "/t/history.sqlite")
        #expect(places.legacyDownloads == "/t/downloads.json" && places.legacyPermissions == "/t/site-permissions.json")
    }
}
