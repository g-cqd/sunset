package import Network

/// A proxy in Network's form: what stores of pages, the proxy check and Sunset's own fetches for pages (`WebFetch`) are given.
extension WebProxy {
    /// The configuration pages are given; the check (`ProxyCheck`) and `WebFetch` too.
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
}
