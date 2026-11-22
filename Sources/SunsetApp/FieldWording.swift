import SunsetCredentials

/// What a field's problem says under it.
enum FieldWording {
    static func problem(_ constraint: FieldConstraint) -> String {
        switch constraint {
            case .required: "Needed to save."
            case .length(let bounds): "Should be \(bounds.lowerBound) to \(bounds.upperBound) characters."
            case .pattern: "Does not have the expected form."
            case .range(let bounds): "Should be a number from \(Int(bounds.lowerBound)) to \(Int(bounds.upperBound))."
            case .luhn: "Not a card number: its check digit is wrong."
            case .inTheFuture: "Already past."
            case .oneOf(let options): "One of \(options.joined(separator: ", "))."
        }
    }
}
