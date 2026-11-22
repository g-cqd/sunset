internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// The switch of `features` named `key`.
    private static func path(_ key: String) -> WritableKeyPath<Configuration.Features, Bool>? {
        switch key {
            case "terminal": \.terminal
            case "web": \.web
            case "documents": \.documents
            case "credentials": \.credentials
            default: nil
        }
    }

    /// `features`: `terminal`, `web`, `documents`, `credentials`. All three tab scopes off is said, and terminals stay: an
    /// app that does nothing has no window to turn anything back on in.
    mutating func readFeatures(_ object: Object) {
        for (key, value) in object {
            guard let path = Self.path(key) else {
                unknown("features.\(key)")
                continue
            }
            if let flag = bool("features.\(key)", value) { configuration.features[keyPath: path] = flag }
        }
        if configuration.features.count == 0 {
            issue("features", "at least one of terminal, web and documents stays on: terminal is on")
            configuration.features.terminal = true
        }
    }
}
