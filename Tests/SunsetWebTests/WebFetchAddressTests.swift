import Foundation
import Testing

@testable import SunsetWebModel

/// What Sunset fetches for a page goes only where the page could send a visitor's browser on the open web: public
/// addresses, or the page's own host (the outside audit's HIGH-01, 2026-11-22; as Private Network Access keeps a public
/// page from this Mac and the local network). Through the page's proxy, names are left to the proxy.
@Suite("Fetching for a page: where it may go", .serialized)
struct WebFetchAddressTests {
    private let page = URL(string: "https://example.com/article")

    @Test func `a page's fetch does not reach this Mac, by its address or by a name for it`() async throws {
        let server = try EchoServer()
        for host in ["127.0.0.1", "localhost", "[::1]"] {
            let address = try #require(URL(string: "http://\(host):\(server.port)/icon.png"))
            #expect(await WebFetch.data(address, agent: "Safari", limit: 1 << 20, for: page) == nil, "\(host)")
        }
        #expect(server.received.isEmpty)
    }

    @Test func `a page on this Mac has its own icon fetched, and an address the user gave is fetched`() async throws {
        let server = try EchoServer()
        let address = try #require(URL(string: "http://127.0.0.1:\(server.port)/icon.png"))
        let local = try #require(URL(string: "http://127.0.0.1:\(server.port)/"))
        #expect(await WebFetch.data(address, agent: "Safari", limit: 1 << 20, for: local) != nil)
        #expect(await WebFetch.data(address, agent: "Safari", limit: 1 << 20, for: nil) != nil)
        #expect(server.received.count == 2)
    }

    @MainActor @Test func `through the page's proxy: the name is left to the proxy, not looked up here`() async throws {
        let proxy = try await AnsweringProxy.start()
        defer { proxy.stop() }
        let address = try #require(URL(string: "http://icons.example.invalid/icon.png"))
        let through = WebProxy(kind: .http, host: "127.0.0.1", port: proxy.port)
        let fetched = await WebFetch.data(address, agent: "Safari", limit: 1 << 20, for: page, proxy: through)
        #expect(fetched != nil)
        #expect(proxy.requests.first?.contains("icons.example.invalid") == true, "\(proxy.requests)")
    }

    @Test func `which addresses are public`() throws {
        let kept = [
            "127.0.0.1", "10.1.2.3", "172.16.0.1", "172.31.255.255", "192.168.1.1", "169.254.169.254", "100.64.0.1",
            "0.0.0.0", "224.0.0.1", "255.255.255.255", "198.18.0.1", "192.0.2.1", "::1", "::", "fe80::1", "febf::1",
            "fc00::1", "fd12::1", "ff02::1", "::ffff:127.0.0.1", "::ffff:10.0.0.1", "64:ff9b::a00:1", "2001:db8::1",
            "2002::1", "fec0::1"
        ]
        for address in kept {
            let bytes = try #require(PublicAddress.literal(address), "\(address)")
            #expect(!PublicAddress.isPublic(bytes), "\(address)")
        }
        for address in ["93.184.216.34", "1.1.1.1", "172.32.0.1", "2606:4700::1111", "::ffff:8.8.8.8", "2a00:1450::1"] {
            let bytes = try #require(PublicAddress.literal(address), "\(address)")
            #expect(PublicAddress.isPublic(bytes), "\(address)")
        }
        #expect(PublicAddress.literal("example.com") == nil)
    }
}
