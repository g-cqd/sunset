/// A configuration file that cannot be read at all: the configuration in force stays as it is.
public enum ConfigurationError: Error, Sendable, Equatable {
    /// The text is not valid JSON (comments and trailing commas are allowed); `offset` is the byte where it went wrong, when known.
    case syntax(message: String, offset: Int?)
    /// The top level is not an object.
    case notAnObject
}
