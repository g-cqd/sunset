public import Foundation
internal import InternedStrings

/// WebKit's "developer extras" preference, which adds Inspect Element to a page's context menu and opens the inspector inside the app (R1: behind a
/// setting, on by default). Not public API: set by name when the preferences object answers to it, and nothing happens when it does not.
public enum WebDeveloperExtras {
    @MainActor
    public static func set(_ enabled: Bool, on preferences: NSObject) {
        // WebKit's accessors carry an underscore (`_setDeveloperExtrasEnabled:`); key-value coding finds them under the plain
        // key. Checked for the plain getter, the preference was never set (the owner, 2026-11-18: no Inspect Element).
        let key = #Interned("developerExtrasEnabled")
        guard preferences.responds(to: NSSelectorFromString(#Interned("_setDeveloperExtrasEnabled:"))) else { return }
        preferences.setValue(enabled, forKey: key)
    }
}
