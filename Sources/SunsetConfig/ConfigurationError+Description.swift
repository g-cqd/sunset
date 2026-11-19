extension ConfigurationError: CustomStringConvertible {
    /// What is wrong with the file, as a person reads it: where the syntax broke, or that it is not one object.
    public var description: String {
        switch self {
            case .syntax(let message, let offset): offset.map { "\(message) (byte \($0))" } ?? message
            case .notAnObject: "the file must contain an object ({ ... })"
        }
    }
}
