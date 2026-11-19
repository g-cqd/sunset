internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// The switches of `web`, by key. Never changed after it is made (key paths are not marked Sendable).
    private nonisolated(unsafe) static let webFlags: [String: WritableKeyPath<Configuration.Web, Bool>] = [
        "openLinksInSunset": \.openLinksInSunset, "developer": \.developer, "suggestions": \.suggestions,
        "httpFallback": \.httpFallback, "agentScripts": \.agentScripts, "textOnlyZoom": \.textOnlyZoom,
        "clearHistoryOnQuit": \.clearHistoryOnQuit, "shareOtherProfiles": \.shareOtherProfiles,
        "askWhereToSave": \.askWhereToSave, "openSafeDownloads": \.openSafeDownloads,
        "notifyDownloads": \.notifyDownloads,
        "approveRiskyDownloads": \.approveRiskyDownloads, "privateSuggestions": \.privateSuggestions,
        "privateWindowShares": \.privateWindowShares, "unloadUnderPressure": \.unloadUnderPressure,
        "blocking": \.blocking, "notificationsWithoutClick": \.notificationsWithoutClick,
        "workerNotifications": \.workerNotifications
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
                case "blockingLists": readBlockingLists(value)
                case "proxy": readProxy(value)
                case "keep": section("web.keep", value) { reader, object in reader.readKeep(object) }
                // Before ADR-0081: one switch that cleared everything at quit.
                case "clearWebsiteDataOnQuit":
                    if bool("web.clearWebsiteDataOnQuit", value) == true {
                        configuration.web.keep = .init(
                            cache: .clearOnQuit,
                            traces: .clearOnQuit,
                            siteData: .clearOnQuit
                        )
                    }
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
            case "agent":
                if let agent = choice(path, value, as: Configuration.Web.Agent.self) { configuration.web.agent = agent }
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
