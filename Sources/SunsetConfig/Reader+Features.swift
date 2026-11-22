internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// `features`: `terminal`, `web`, `documents`. All three off is said, and terminals stay: an app that does nothing
    /// has no window to turn anything back on in.
    mutating func readFeatures(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "terminal":
                    if let flag = bool("features.terminal", value) { configuration.features.terminal = flag }
                case "web": if let flag = bool("features.web", value) { configuration.features.web = flag }
                case "documents":
                    if let flag = bool("features.documents", value) { configuration.features.documents = flag }
                case "credentials":
                    if let flag = bool("features.credentials", value) { configuration.features.credentials = flag }
                default: unknown("features.\(key)")
            }
        }
        if configuration.features.count == 0 {
            issue("features", "at least one of terminal, web and documents stays on: terminal is on")
            configuration.features.terminal = true
        }
    }
}
