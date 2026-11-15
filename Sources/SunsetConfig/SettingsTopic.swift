/// A topic of a section of Settings: one page of options (roadmap 0032).
public struct SettingsTopic: Sendable, Identifiable {
    /// The section's identifier, a dot, and its own ("terminal.cursor").
    public let id: String
    public let title: String
    public let options: [SettingsOption]

    init(_ id: String, _ title: String, _ options: [SettingsOption]) {
        self.id = id
        self.title = title
        self.options = options.map { option in
            var placed = option
            placed.topic = id
            return placed
        }
    }
}
