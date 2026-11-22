package import Foundation

/// The app's side: a profile's page settings (its own over all profiles').
@MainActor
package enum WebProfiles {
    /// Every profile, by id (nil for the first) and name, in their order.
    package static var all: () -> [(id: UUID?, name: String)] = { [] }
    package static var settings: (_ profile: UUID?, _ like: WebSettings) -> WebSettings = { profile, like in
        var settings = like
        settings.profile = profile
        return settings
    }
}
