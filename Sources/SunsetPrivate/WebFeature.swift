public import Foundation
internal import InternedStrings

/// One of WebKit's features by its key, among the preferences' features (not public API): set on or off; nothing happens
/// when the key is not there.
public enum WebFeature {
    @MainActor
    public static func set(_ key: String, enabled: Bool, on preferences: NSObject) {
        let list = #Interned("_features")
        let setter = NSSelectorFromString(#Interned("_setEnabled:forFeature:"))
        guard let type = type(of: preferences) as AnyObject as? NSObject,
            type.responds(to: NSSelectorFromString(list)),
            preferences.responds(to: setter),
            let features = type.value(forKey: list) as? [NSObject],
            let feature = features.first(where: { ($0.value(forKey: "key") as? String) == key })
        else { return }
        typealias Setter = @convention(c) (NSObject, Selector, Bool, NSObject) -> Void
        let call = unsafeBitCast(preferences.method(for: setter), to: Setter.self)
        call(preferences, setter, enabled, feature)
    }
}
