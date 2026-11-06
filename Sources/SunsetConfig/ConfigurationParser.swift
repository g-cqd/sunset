internal import AemiJSONCore

/// Reads a configuration from text: JSON with comments and trailing commas (JSON5), so that the file can be annotated. A key that is wrong is reported with its
/// path and leaves the default in force, so one typo does not throw the rest of the file away; text that is not JSON at all is an error, and the caller keeps
/// the configuration it has.
public enum ConfigurationParser {
    /// What was read: the configuration, and what in the file was not usable.
    public struct Result: Sendable, Equatable {
        public var configuration: Configuration
        public var issues: [ConfigurationIssue]
    }

    public static func parse(_ text: String) throws(ConfigurationError) -> Result {
        let root: JSONValue
        do {
            root = try JSONValue(parsing: text, options: JSONParseOptions(validation: .json5))
        } catch {
            throw ConfigurationError.syntax(message: describe(error), offset: offset(of: error))
        }
        guard case .object(let object) = root else { throw ConfigurationError.notAnObject }
        var reader = Reader()
        reader.read(object)
        return Result(configuration: reader.configuration, issues: reader.issues)
    }

    private static func describe(_ error: JSONError) -> String {
        switch error {
            case .unexpectedEndOfInput: "the file ends in the middle of a value"
            case .unexpectedCharacter(let byte, _): "unexpected character '\(Unicode.Scalar(byte))'"
            case .invalidNumber: "not a valid number"
            case .invalidString: "not a valid string"
            case .depthExceeded: "nested too deeply"
            case .trailingData: "something follows the end of the object"
            case .documentTooLarge: "the file is too large"
            case .invalidUTF8: "the file is not valid UTF-8"
            case .duplicateKey: "a key appears twice"
        }
    }

    private static func offset(of error: JSONError) -> Int? {
        switch error {
            case .unexpectedCharacter(_, let at), .invalidNumber(let at), .invalidString(let at),
                .depthExceeded(let at),
                .trailingData(let at), .invalidUTF8(let at), .duplicateKey(let at):
                at
            case .unexpectedEndOfInput, .documentTooLarge:
                nil
        }
    }
}
