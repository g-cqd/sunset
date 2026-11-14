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

    @Test func `the files of before the database are still found, to be imported`() {
        let places = StoragePlaces(environment: ["SUNSET_CONFIG": "/t/config.json"], home: "/h")
        #expect(places.legacyZoom == "/t/site-zoom.json" && places.legacyHistory == "/t/history.sqlite")
        #expect(places.legacyDownloads == "/t/downloads.json" && places.legacyPermissions == "/t/site-permissions.json")
    }
}
