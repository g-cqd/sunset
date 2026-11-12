import Foundation
import Testing

@testable import SunsetWeb

@Suite("What the command bar takes for an address") struct WebAddressTests {
    @Test func `a dotted host, a port, a slash, a scheme or localhost is an address`() {
        #expect(WebAddress.typedAddress("example.com")?.absoluteString == "https://example.com")
        #expect(WebAddress.typedAddress("nas:8080")?.absoluteString == "https://nas:8080")
        #expect(WebAddress.typedAddress("nas/")?.absoluteString == "https://nas/")
        #expect(WebAddress.typedAddress("http://a")?.absoluteString == "http://a")
        #expect(WebAddress.typedAddress("10.0.0.1")?.absoluteString == "https://10.0.0.1")
        #expect(WebAddress.typedAddress("localhost") != nil)
    }

    @Test func `a word alone, words, a trailing dot or a version number are not`() {
        #expect(WebAddress.typedAddress("projects") == nil)
        #expect(WebAddress.typedAddress("two words") == nil)
        #expect(WebAddress.typedAddress("end.") == nil)
        #expect(WebAddress.typedAddress("1.2") == nil)
        #expect(WebAddress.typedAddress("") == nil)
    }
}
