import WebKit

/// The in-memory stores of private pages, one per group, alive while a page of the group holds it (web step h).
@MainActor
enum PrivateStores {
    private static let stores = NSMapTable<NSUUID, WKWebsiteDataStore>(
        keyOptions: .strongMemory,
        valueOptions: .weakMemory
    )

    static func store(for privacy: PagePrivacy) -> WKWebsiteDataStore {
        let key = privacy.group as NSUUID
        if let store = stores.object(forKey: key) { return store }
        let store = WKWebsiteDataStore.nonPersistent()
        stores.setObject(store, forKey: key)
        return store
    }
}
