import AppKit
import SunsetConfig

extension AppConfiguration {
    /// `appearance.icon` on the Dock tile and in the app switcher: an alternate from the asset catalog, or the bundle's
    /// own (`nil`) for Sunset, so that the system's light, dark and tinted forms of it stay.
    func applyIcon() {
        let icon = configuration.appearance.icon
        NSApp?.applicationIconImage = icon == .sunset ? nil : NSImage(named: icon.assetName)
    }
}
