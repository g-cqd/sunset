package import WebKit

/// A proxy given to a store of pages: the store's own list (its Network form: `WebProxy+Network`).
extension WebProxy {
    /// Gives the store this proxy; every page of it goes through it.
    @MainActor package func apply(to store: WKWebsiteDataStore) {
        store.proxyConfigurations = [configuration]
    }

    /// Takes the proxy away from a store.
    @MainActor package static func clear(_ store: WKWebsiteDataStore) {
        store.proxyConfigurations = []
    }

    /// The app's (`web.proxy`): every store a page is made with is given it.
    @MainActor package static var current: WebProxy?

    /// Gives a store the app's proxy, or none.
    @MainActor package static func applyCurrent(to store: WKWebsiteDataStore) {
        if let current { current.apply(to: store) } else { clear(store) }
    }
}
