import AppKit
import Foundation
import SunsetConfig
import SunsetRuntime

extension AppConfiguration {
    /// `appearance.icon` on the Dock tile and in the app switcher (n142): Auto follows the time of day through the four
    /// skies and schedules the next change; a fixed sky stays until changed. Sunset uses the bundle's own icon (`nil`)
    /// so that the system's light, dark and tinted forms of it stay.
    func applyIcon() {
        iconSchedule?.cancel()
        iconSchedule = nil
        let choice = configuration.appearance.icon
        let now = runtime.now()
        let sky = choice.resolved(at: now)
        NSApp?.applicationIconImage = sky == .sunset ? nil : NSImage(named: sky.assetName)
        guard choice == .auto else { return }
        let wait = Configuration.Appearance.Icon.secondsUntilNextChange(from: now)
        iconSchedule = runtime.task(role: .observation) { [weak self] in
            guard let self, await runtime.sleep(for: .seconds(wait)) else { return }
            applyIcon()
        }
    }

    /// Re-evaluates the automatic icon after wake or a system clock change so a sleeping Mac catches up right away.
    func watchIconDay() {
        guard iconObservers.isEmpty else { return }
        iconObservers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    if self?.configuration.appearance.icon == .auto { self?.applyIcon() }
                }
            }
        )
        iconObservers.append(
            NotificationCenter.default.addObserver(
                forName: .NSSystemClockDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    if self?.configuration.appearance.icon == .auto { self?.applyIcon() }
                }
            }
        )
    }
}
