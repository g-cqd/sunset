internal import AemiJSONCore

/// Reads a configuration from text: JSON with comments and trailing commas (JSON5), so that the file can be annotated. A key that is wrong is reported with its
/// path and leaves the default in force, so one typo does not throw the rest of the file away; text that is not JSON at all is an error, and the caller keeps
/// the configuration it has.
public enum ConfigurationParser {
    /// What was read: the configuration, and what in the file was not usable.
    public struct Result: Sendable, Equatable {
        public var configuration: Configuration
        public var issues: [ConfigurationIssue]
        /// The file has keys in their former places (`font`, `colors`, …): it is to be written again with the new ones.
        public var hasFormerKeys = false
        /// The file has settings or values of before the look settings had one per scheme (the tint's light keys,
        /// `web.pageScheme`, an opaque or filled window): it is to be written again with the present ones.
        public var hasFormerValues = false
    }

    /// Which keys a file may set: all of them, or only the visual ones (a theme).
    public enum Scope: Sendable { case file, theme }

    /// `base` is what a key the text does not mention keeps (the defaults, or a theme's configuration).
    public static func parse(
        _ text: String,
        base: Configuration = Configuration(),
        scope: Scope = .file
    ) throws(ConfigurationError) -> Result {
        let root: JSONValue
        do {
            root = try JSONValue(parsing: text, options: JSONParseOptions(validation: .json5))
        } catch {
            throw ConfigurationError.syntax(message: describe(error), offset: offset(of: error))
        }
        guard case .object(let object) = root else { throw ConfigurationError.notAnObject }
        var reader = Reader(configuration: base, scope: scope)
        // The file's keys follow the sections; the settings keep their names (design 0009).
        reader.read(FileKeys.inside(object))
        reader.finish()
        let issues = reader.issues.map { issue in
            var said = issue
            said.path = FileKeys.file(issue.path)
            return said
        }
        return Result(
            configuration: reader.configuration,
            issues: issues,
            hasFormerKeys: FileKeys.hasFormerKeys(object),
            hasFormerValues: reader.migrated
        )
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
