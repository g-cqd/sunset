extension ConfigurationWriter {
    /// The keys added since the table below was full: the web pane's and a few others.
    static func extras(_ configuration: Configuration) -> [String: String] {
        var extra = web(configuration.web).merging(permissions(configuration.web)) { $1 }
        extra["appearance.tint.light"] = color(configuration.appearance.lightTintColor)
        extra["features.terminal"] = String(configuration.features.terminal)
        extra["features.web"] = String(configuration.features.web)
        extra["features.documents"] = String(configuration.features.documents)
        extra["features.credentials"] = String(configuration.features.credentials)
        extra["tabs.startAddress"] = string(configuration.tabs.startAddress)
        extra["tabs.startFile"] = string(configuration.tabs.startFile)
        extra["tabs.startProfile"] = string(configuration.tabs.startProfile)
        return extra
    }
}
