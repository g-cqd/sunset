import Foundation
import SunsetPane
import Testing

/// What is typed in a page's address field: an address, or words to search for.
@Suite("Web address") struct WebAddressTests {
    private func address(_ text: String) -> String? { WebAddress.url(for: text)?.absoluteString }

    @Test func `an address with its scheme is taken as it is`() {
        #expect(address("https://example.com/a?b=c#d") == "https://example.com/a?b=c#d")
        #expect(address("  http://example.com  ") == "http://example.com")
        #expect(address("file:///tmp/page.html") == "file:///tmp/page.html")
        #expect(address("about:blank") == "about:blank")
    }

    @Test func `a host without a scheme gets https, and this machine gets http`() {
        #expect(address("example.com") == "https://example.com")
        #expect(address("example.com/path?q=1") == "https://example.com/path?q=1")
        #expect(address("localhost:3000") == "http://localhost:3000")
        #expect(address("localhost") == "http://localhost")
        #expect(address("127.0.0.1:8080/x") == "http://127.0.0.1:8080/x")
        #expect(address("192.168.1.10") == "http://192.168.1.10")
        #expect(address("[::1]:8080") == "http://[::1]:8080")
        #expect(address("nas.local/files") == "http://nas.local/files")
    }

    @Test func `anything else is searched for, with the words safely in the address`() {
        #expect(address("swift concurrency") == "https://duckduckgo.com/?q=swift%20concurrency")
        #expect(address("what is 1+1 & why?") == "https://duckduckgo.com/?q=what%20is%201%2B1%20%26%20why%3F")
        #expect(address("hello") == "https://duckduckgo.com/?q=hello", "one word with no dot is not a host")
        #expect(address("e.g. this") == "https://duckduckgo.com/?q=e.g.%20this", "a space makes it words")
        #expect(
            address("javascript:alert(1)") == "https://duckduckgo.com/?q=javascript%3Aalert(1)",
            "not a scheme that is opened"
        )
    }

    @Test func `nothing typed is no address`() {
        #expect(address("") == nil && address("   \n") == nil)
    }
}
