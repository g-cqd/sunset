import Testing

@testable import SunsetCredentials

/// A page's site for filling and saving: its registrable domain; an IP address, `localhost` or a single label is a site
/// of its own (the Public Suffix List would cut "127.0.0.1" to "0.1").
@Suite("A host's site")
struct SiteOfHostTests {
    @Test func `addresses and single labels are their own site; names go to the list`() {
        let list: (String) -> String? = { _ in "cut" }
        #expect(LoginSite.of("127.0.0.1", registrable: list) == "127.0.0.1")
        #expect(LoginSite.of("[::1]", registrable: list) == "[::1]" && LoginSite.of("::1", registrable: list) == "::1")
        #expect(
            LoginSite.of("localhost", registrable: list) == "localhost"
                && LoginSite.of("nas", registrable: list) == "nas"
        )
        #expect(LoginSite.of("accounts.example.com", registrable: list) == "cut")
        #expect(
            LoginSite.of("Example.COM.", registrable: { $0 == "example.com" ? "example.com" : nil }) == "example.com"
        )
        #expect(LoginSite.of("com", registrable: { _ in nil }) == "com", "a host the list does not cut is its own site")
    }
}
