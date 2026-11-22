/// What a field's value should be (ADR-0092). Only `required` blocks a save; the others are said, as warnings.
public enum FieldConstraint: Hashable, Sendable, Codable {
    case required
    /// Its length in characters.
    case length(ClosedRange<Int>)
    /// A regular expression it matches somewhere (anchor it to match it whole).
    case pattern(String)
    /// A number within these bounds.
    case range(ClosedRange<Double>)
    /// A card number's check digit (Luhn).
    case luhn
    /// A date, or a month and year, not past.
    case inTheFuture
    /// Among these options (a choice's own).
    case oneOf([String])

    /// Whether a value that breaks it keeps the entry from being saved.
    public var blocksSave: Bool {
        self == .required
    }
}
