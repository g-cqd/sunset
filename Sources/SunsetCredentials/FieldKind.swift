/// What a field of an entry holds (ADR-0092): how it is shown, typed and checked. A choice carries its options.
public enum FieldKind: Hashable, Sendable, Codable {
    case text, multiline, concealed, oneTimeCode, url, email, phone
    case number, money, date, monthYear, time, toggle
    case choice([String])
    case multipleChoice([String])
    case cardNumber, reference, file, sshKey, address

    /// Hidden until asked for, never searched, kept with a dated history of its own.
    public var isConcealed: Bool {
        switch self {
            case .concealed, .oneTimeCode, .sshKey: true
            default: false
        }
    }

    /// The options a choice is among; nil for any other kind.
    public var options: [String]? {
        switch self {
            case .choice(let options), .multipleChoice(let options): options
            default: nil
        }
    }
}
