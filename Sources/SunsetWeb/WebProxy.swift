import Foundation
import Network
package import WebKit

/// A proxy for the pages (roadmap 0022 W-f, first form; the owner's note n75): an HTTP (CONNECT) or SOCKS5 proxy, given to
/// every store of pages (`WKWebsiteDataStore.proxyConfigurations`). Written `http://host:port` or `socks5://host:port`.
package struct WebProxy: Equatable, Sendable {
    package enum Kind: Sendable { case http, socks }

    package var kind: Kind
    package var host: String
    package var port: Int

    package init(kind: Kind, host: String, port: Int) {
        self.kind = kind
        self.host = host
        self.port = port
    }

    /// Reads an address; nil for anything that is not an http or socks5 proxy with a host and a port.
    package init?(_ address: String) {
        guard let url = URL(string: address), let host = url.host(), !host.isEmpty, let port = url.port,
            (1 ... 65_535).contains(port)
        else { return nil }
        switch url.scheme?.lowercased() {
            case "http": kind = .http
            case "socks5", "socks": kind = .socks
            default: return nil
        }
        self.host = host
        self.port = port
    }

    /// Gives the store this proxy; every page of it goes through it.
    package func apply(to store: WKWebsiteDataStore) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: UInt16(port)) ?? .any
        )
        let configuration: ProxyConfiguration =
            switch kind {
                case .http: ProxyConfiguration(httpCONNECTProxy: endpoint)
                case .socks: ProxyConfiguration(socksv5Proxy: endpoint)
            }
        store.proxyConfigurations = [configuration]
    }

    /// Takes the proxy away from a store.
    package static func clear(_ store: WKWebsiteDataStore) { store.proxyConfigurations = [] }

    /// The app's (`web.proxy`): every store a page is made with is given it.
    @MainActor package static var current: WebProxy?

    /// Gives a store the app's proxy, or none.
    @MainActor package static func applyCurrent(to store: WKWebsiteDataStore) {
        if let current { current.apply(to: store) } else { clear(store) }
    }
}
