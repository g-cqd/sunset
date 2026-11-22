/// A Firefox container: a name, and the colour and icon Firefox shows it with (each becomes a profile).
public struct BrowserContainer: Sendable, Equatable {
    public var name: String
    public var color: String?
    public var icon: String?

    public init(name: String, color: String? = nil, icon: String? = nil) {
        self.name = name
        self.color = color
        self.icon = icon
    }
}
