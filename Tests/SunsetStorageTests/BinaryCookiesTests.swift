import Foundation
import Testing

@testable import SunsetStorage

/// Roadmap 0112 E: Sunset's cookies brought into Sunset WebKit, read from Sunset's jar (CFNetwork's `binarycookies`), never
/// by sharing WebKit's files. The jar here was written by WebKit itself (2026-11-22, a probe that set three cookies in a
/// store of its own: diary 2026-11-22-05), no one's real cookies.
@Suite("A cookie jar read")
struct BinaryCookiesTests {
    private let jar = CookieJarFixture.jar

    @Test func `every cookie, with its domain, path, value, expiry and flags`() throws {
        let cookies = try BinaryCookies.read(try #require(jar)).sorted { $0.name < $1.name }
        try #require(cookies.map(\.name) == ["httponly", "plain", "secure"])
        // Asked to last until 2033, kept 400 days from when they were set (2026-11-22): WebKit caps a cookie's life as
        // RFC 6265bis says.
        let expiry = Date(timeIntervalSince1970: 1_795_341_069 + 400 * 86_400)
        #expect(cookies.allSatisfy { $0.expires == expiry })
        let (httpOnly, plain, secure) = (cookies[0], cookies[1], cookies[2])
        #expect(plain.domain == "example.com" && plain.path == "/" && plain.value == "one")
        #expect(plain.hostOnly && !plain.secure && !plain.httpOnly && plain.sameSite == nil)
        #expect(secure.domain == ".example.org" && secure.path == "/app" && secure.value == "two words")
        #expect(secure.secure && !secure.hostOnly && !secure.httpOnly)
        #expect(httpOnly.domain == "sub.example.net" && httpOnly.value == "3")
        #expect(httpOnly.httpOnly && httpOnly.sameSite == .lax && httpOnly.hostOnly)
    }

    @Test func `each becomes the same HTTPCookie, to be set in the other WebKit`() throws {
        let cookies = try BinaryCookies.read(try #require(jar)).sorted { $0.name < $1.name }
        let made = try cookies.map { try #require(HTTPCookie(properties: $0.httpProperties)) }
        #expect(made.map(\.name) == ["httponly", "plain", "secure"])
        #expect(made[0].isHTTPOnly && made[0].sameSitePolicy == .sameSiteLax && !made[0].isSecure)
        #expect(made[1].domain == "example.com" && made[1].value == "one" && made[1].expiresDate == cookies[1].expires)
        #expect(
            made[2].isSecure && made[2].path == "/app" && made[2].domain == ".example.org"
                && made[2].value == "two words"
        )
    }

    @Test func `what is not a jar, or a cut one, is refused, never read past its end`() throws {
        let whole = try #require(jar)
        #expect(throws: BinaryCookies.Unreadable.self) { try BinaryCookies.read(Data("nope".utf8)) }
        for length in [4, 8, 20, 40, 100, 300] {
            #expect(throws: BinaryCookies.Unreadable.self) { try BinaryCookies.read(whole.prefix(length)) }
        }
        var wrong = whole
        wrong[0x24 + 0x14] = 0xFF  // a name's offset past its record
        #expect(throws: BinaryCookies.Unreadable.self) { try BinaryCookies.read(wrong) }
    }
}
