import Testing

@testable import SunsetWebModel

/// One install prompt for one press, however many times the page asks while it is open.
@Suite("Installs underway")
struct InstallsUnderwayTests {
    @Test func `a second request for the same package and profile is dropped until the first ends`() {
        var underway = InstallsUnderway()
        let first = underway.begin("chrome:abc", profile: nil)
        let again = underway.begin("chrome:abc", profile: nil)
        let otherProfile = underway.begin("chrome:abc", profile: "work")
        let otherPackage = underway.begin("firefox:ublock-origin", profile: nil)
        underway.end("chrome:abc", profile: nil)
        let after = underway.begin("chrome:abc", profile: nil)
        #expect(first && !again)
        #expect(otherProfile && otherPackage)
        #expect(after, "asked again once the first ended")
    }
}
