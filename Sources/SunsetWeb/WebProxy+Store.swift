package import Network
package import WebKit

/// A proxy given to a store of pages: Network's form of it, and the store's own list.
extension WebProxy {
    /// The configuration pages are given, and the check (`ProxyCheck`) too.
    package var configuration: ProxyConfiguration {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: UInt16(port)) ?? .any
        )
        return switch kind {
            case .http: ProxyConfiguration(httpCONNECTProxy: endpoint)
            case .socks: ProxyConfiguration(socksv5Proxy: endpoint)
        }
    }

    /// Gives the store this proxy; every page of it goes through it.
    package func apply(to store: WKWebsiteDataStore) {
        store.proxyConfigurations = [configuration]
    }

    /// Takes the proxy away from a store.
    package static func clear(_ store: WKWebsiteDataStore) {
        store.proxyConfigurations = []
    }

    /// The app's (`web.proxy`): every store a page is made with is given it.
    @MainActor package static var current: WebProxy?

    /// Gives a store the app's proxy, or none.
    @MainActor package static func applyCurrent(to store: WKWebsiteDataStore) {
        if let current { current.apply(to: store) } else { clear(store) }
    }
}
