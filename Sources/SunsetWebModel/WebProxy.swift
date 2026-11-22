import Foundation

/// A proxy for the pages (first form): an HTTP (CONNECT) or SOCKS5 proxy, given to every store of pages
/// (`WKWebsiteDataStore.proxyConfigurations`). Written `http://host:port` or `socks5://host:port`.
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
}
