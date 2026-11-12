internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// The switches of `web`, by key. Never changed after it is made (key paths are not marked Sendable).
    private nonisolated(unsafe) static let webFlags: [String: WritableKeyPath<Configuration.Web, Bool>] = [
        "openLinksInSunset": \.openLinksInSunset, "developer": \.developer, "suggestions": \.suggestions,
        "httpFallback": \.httpFallback, "textOnlyZoom": \.textOnlyZoom,
        "clearHistoryOnQuit": \.clearHistoryOnQuit, "clearWebsiteDataOnQuit": \.clearWebsiteDataOnQuit,
        "askWhereToSave": \.askWhereToSave, "openSafeDownloads": \.openSafeDownloads,
        "notifyDownloads": \.notifyDownloads,
        "approveRiskyDownloads": \.approveRiskyDownloads, "privateSuggestions": \.privateSuggestions,
        "privateWindowShares": \.privateWindowShares
    ]

    mutating func readWeb(_ object: Object) {
        for (key, value) in object {
            if let path = Self.webFlags[key] {
                if let flag = bool("web.\(key)", value) { configuration.web[keyPath: path] = flag }
                continue
            }
            switch key {
                case "engine": if let name = string("web.engine", value) { configuration.web.engine = name }
                case "engines": readEngines(value)
                case "permissions":
                    section("web.permissions", value) { reader, object in reader.readPermissions(object) }
                case "downloadFolder":
                    if let path = string("web.downloadFolder", value) { configuration.web.downloadFolder = path }
                default: readWebChoice(key, value)
            }
        }
    }

    private mutating func readWebChoice(_ key: String, _ value: JSONValue) {
        let path = "web.\(key)"
        switch key {
            case "tabIcon":
                if let icon = choice(path, value, as: Configuration.Web.TabIcon.self) {
                    configuration.web.tabIcon = icon
                }
            case "address":
                if let place = choice(path, value, as: Configuration.Web.AddressPlace.self) {
                    configuration.web.address = place
                }
            case "zoomScope":
                if let scope = choice(path, value, as: Configuration.Web.ZoomScope.self) {
                    configuration.web.zoomScope = scope
                }
            case "historyKeep":
                if let keep = choice(path, value, as: Configuration.Web.HistoryKeep.self) {
                    configuration.web.historyKeep = keep
                }
            case "keepDownloads":
                if let keep = choice(path, value, as: Configuration.Web.DownloadsKeep.self) {
                    configuration.web.keepDownloads = keep
                }
            case "windowBar":
                if let edge = choice(path, value, as: Configuration.Web.BarEdge.self) {
                    configuration.web.windowBar = edge
                }
            default: unknown(path)
        }
    }

    private mutating func readPermissions(_ object: Object) {
        for (key, value) in object {
            let path = "web.permissions.\(key)"
            guard Configuration.Web.permissionNames.contains(key) else {
                unknown(path)
                continue
            }
            if let answer = choice(path, value, as: Configuration.Web.PermissionDefault.self) {
                configuration.web.permissions[key] = answer
            }
        }
    }
}
