/// What a site can be allowed (web step g).
package enum SitePermission: String, CaseIterable, Codable, Sendable {
    case camera, microphone, screen, location, notifications, popups, autoplay

    package var title: String {
        switch self {
            case .camera: "Camera"
            case .microphone: "Microphone"
            case .screen: "Screen Sharing"
            case .location: "Location"
            case .notifications: "Notifications"
            case .popups: "Pop-up Windows"
            case .autoplay: "Auto-Play with Sound"
        }
    }

    /// What the panel says the site wants.
    package var request: String {
        switch self {
            case .camera: "use your camera"
            case .microphone: "use your microphone"
            case .screen: "see your screen"
            case .location: "know your location"
            case .notifications: "send you notifications"
            case .popups: "open a pop-up window"
            case .autoplay: "play sound on its own"
        }
    }

    package var symbol: String {
        switch self {
            case .camera: "video"
            case .microphone: "mic"
            case .screen: "rectangle.on.rectangle"
            case .location: "location"
            case .notifications: "bell"
            case .popups: "macwindow.on.rectangle"
            case .autoplay: "speaker.wave.2"
        }
    }

    /// The owner's defaults: asked, except pop-ups and sound, blocked.
    package var defaultAnswer: PermissionAnswer { self == .popups || self == .autoplay ? .deny : .ask }

    /// What macOS itself must also allow Sunset (its identity, Sunset.app, and usage strings).
    package var needsAppIdentity: Bool { self == .camera || self == .microphone || self == .location }
}
