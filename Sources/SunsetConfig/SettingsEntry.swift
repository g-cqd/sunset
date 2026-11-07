/// One option of the Settings window, for search: what it is called, and other words people look it up by.
public struct SettingsEntry: Sendable, Equatable {
    public var id: String
    /// The pane that holds it.
    public var pane: String
    public var title: String
    public var keywords: [String]

    public init(id: String, pane: String, title: String, keywords: [String]) {
        self.id = id
        self.pane = pane
        self.title = title
        self.keywords = keywords
    }
}
