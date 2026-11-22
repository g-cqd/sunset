package import Foundation
import WebKit

/// A profile's website data: the WebKit data store that has the profile's id.
package enum ProfileData {
    /// Erases the website data of a profile that was removed: its cookies, logins and storage. The pages that used it
    /// must be gone (WebKit refuses while a view holds the store).
    /// - Returns: whether it was erased.
    @MainActor
    package static func erase(_ profile: UUID) async -> Bool {
        (try? await WKWebsiteDataStore.remove(forIdentifier: profile)) != nil
    }
}
