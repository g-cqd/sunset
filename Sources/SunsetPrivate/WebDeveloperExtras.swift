public import Foundation
internal import InternedStrings

/// WebKit's "developer extras" preference, which adds Inspect Element to a page's context menu and opens the inspector inside the app (R1: behind a
/// setting, on by default). Not public API: set by name when the preferences object answers to it, and nothing happens when it does not.
public enum WebDeveloperExtras {
    @MainActor
    public static func set(_ enabled: Bool, on preferences: NSObject) {
        let key = #Interned("developerExtrasEnabled")
        guard preferences.responds(to: NSSelectorFromString(key)) else { return }
        preferences.setValue(enabled, forKey: key)
    }
}
