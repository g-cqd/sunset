import AVFoundation
import AppKit
import CoreLocation
import Observation
import SunsetRuntime
import SunsetWeb
import UserNotifications

/// What macOS lets Sunset do now: notifications, the camera, the microphone, the location; looked at when the app starts
/// and each time it comes to the front (a change in System Settings is seen on coming back), and after asking.
@MainActor @Observable
final class SystemAuthorizations {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    @ObservationIgnored var runtime = Runtime.live

    static let shared = SystemAuthorizations()

    private(set) var statuses: [SystemAsk.Need: SystemAsk.Status] = [:]
    @ObservationIgnored private var watch: (any NSObjectProtocol)?

    /// What to ask now: what a site may use and macOS has not allowed (`SystemAsk.needed`).
    var asks: [SystemAsk] {
        SystemAsk.needed(statuses, sites: SitePermissions.shared)
    }

    /// Looks now, and again whenever the app comes to the front. Only for an app with a bundle (the notification centre stops
    /// a bare executable).
    func start() {
        guard Bundle.main.bundleIdentifier != nil, watch == nil else { return }
        watch = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { SystemAuthorizations.shared.refresh() }
        }
        refresh()
    }

    func refresh() {
        statuses[.camera] = Self.status(AVCaptureDevice.authorizationStatus(for: .video))
        statuses[.microphone] = Self.status(AVCaptureDevice.authorizationStatus(for: .audio))
        statuses[.location] =
            switch CLLocationManager().authorizationStatus {
                case .notDetermined: .notAsked
                case .denied, .restricted: .denied
                default: .allowed
            }
        runtime.task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            statuses[.notifications] =
                switch settings.authorizationStatus {
                    case .notDetermined: .notAsked
                    case .denied: .denied
                    default: .allowed
                }
        }
    }

    /// Does what the call to action says: asks macOS (it shows its own question), or opens System Settings where it was refused.
    func act(on ask: SystemAsk) {
        switch ask.action {
            case .ask:
                runtime.task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    refresh()
                }
            case .openSettings:
                let pane =
                    switch ask.need {
                        case .notifications:
                            "com.apple.preference.notifications?id=\(Bundle.main.bundleIdentifier ?? "")"
                        case .camera: "com.apple.preference.security?Privacy_Camera"
                        case .microphone: "com.apple.preference.security?Privacy_Microphone"
                        case .location: "com.apple.preference.security?Privacy_LocationServices"
                    }
                if let url = URL(string: "x-apple.systempreferences:\(pane)") { NSWorkspace.shared.open(url) }
        }
    }

    private static func status(_ status: AVAuthorizationStatus) -> SystemAsk.Status {
        switch status {
            case .notDetermined: .notAsked
            case .denied, .restricted: .denied
            default: .allowed
        }
    }
}
