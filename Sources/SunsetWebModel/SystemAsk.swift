/// Something macOS must allow Sunset itself for a page to have it: asked about under the sidebar's field only while a
/// site may use it (allowed, or allowed by default) and macOS has not allowed it.
package struct SystemAsk: Equatable, Sendable, Identifiable {
    package enum Need: String, CaseIterable, Sendable {
        case notifications, camera, microphone, location

        /// The site permission that needs it.
        package var permission: SitePermission {
            switch self {
                case .notifications: .notifications
                case .camera: .camera
                case .microphone: .microphone
                case .location: .location
            }
        }

        package var symbol: String {
            permission.symbol
        }
    }

    /// What macOS says of it now.
    package enum Status: Sendable {
        case notAsked, denied, allowed
    }

    /// What the call to action does: ask macOS now (it shows its own question), or open System Settings where it was refused.
    package enum Action: Sendable {
        case ask, openSettings
    }

    package let need: Need
    package let status: Status

    package var id: String {
        need.rawValue
    }

    package var action: Action {
        status == .notAsked && need == .notifications ? .ask : .openSettings
    }

    /// What it says.
    package var sentence: String {
        let what =
            switch need {
                case .notifications: "send notifications"
                case .camera: "use the camera"
                case .microphone: "use the microphone"
                case .location: "know your location"
            }
        return status == .denied
            ? "macOS does not let Sunset \(what), which a site you allowed asks for."
            : "Let Sunset \(what), as a site you allowed asks."
    }

    package var button: String {
        action == .ask ? "Allow\u{2026}" : "Open System Settings"
    }

    /// What to ask, in the order of `Need`: what a site may use and macOS has not allowed. The camera, the microphone and the
    /// location are asked by macOS itself when a page first needs them: only a refusal is shown for them.
    @MainActor
    package static func needed(_ statuses: [Need: Status], sites: SitePermissions) -> [SystemAsk] {
        Need.allCases.compactMap { need in
            guard let status = statuses[need], status != .allowed else { return nil }
            if need != .notifications, status == .notAsked { return nil }
            let allowed =
                sites.defaults[need.permission] == .allow
                || sites.sites(for: need.permission).contains { $0.answer == .allow }
            return allowed ? SystemAsk(need: need, status: status) : nil
        }
    }
}
