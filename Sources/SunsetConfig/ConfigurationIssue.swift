/// Something wrong in a configuration file that does not stop it from being used: the key is named, and the value in force is the default.
public struct ConfigurationIssue: Sendable, Equatable {
    /// The key as written in the file: `font.size`.
    public var path: String
    public var message: String

    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }
}
