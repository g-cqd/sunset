import Foundation

extension FieldConstraint {
    /// Whether `value` keeps to it at `now`. An empty value keeps to every constraint but `required`: what is not there
    /// is not wrong.
    func holds(for value: String, now: Date) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if self == .required { return !trimmed.isEmpty }
        guard !trimmed.isEmpty else { return true }
        switch self {
            case .required: return true
            case .length(let bounds): return bounds.contains(value.count)
            case .pattern(let pattern): return (try? Regex(pattern)).map { value.firstMatch(of: $0) != nil } ?? true
            case .range(let bounds): return Double(trimmed).map(bounds.contains) ?? false
            case .luhn: return Self.luhn(trimmed)
            case .inTheFuture: return Self.ends(trimmed).map { $0 > now } ?? false
            case .oneOf(let options):
                return trimmed.split(separator: ",")
                    .allSatisfy { options.contains($0.trimmingCharacters(in: .whitespaces)) }
        }
    }

    /// The Luhn check of the digits, spaces and dashes ignored; anything else fails.
    private static func luhn(_ text: String) -> Bool {
        let digits = text.filter { $0 != " " && $0 != "-" }
        guard digits.count >= 2, digits.allSatisfy(\.isASCII), digits.allSatisfy(\.isNumber) else { return false }
        let sum = digits.reversed().enumerated()
            .reduce(0) { total, item in
                let digit = item.element.wholeNumberValue ?? 0
                guard item.offset % 2 == 1 else { return total + digit }
                let doubled = digit * 2
                return total + (doubled > 9 ? doubled - 9 : doubled)
            }
        return sum % 10 == 0
    }

    /// When a date ("2030-04-30") or a month ("2030-04") ends, in UTC; nil when it is neither.
    private static func ends(_ text: String) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 || parts.count == 3, parts.count == text.split(separator: "-").count else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let start = DateComponents(year: parts[0], month: parts[1], day: parts.count == 3 ? parts[2] : 1)
        guard let first = calendar.date(from: start) else { return nil }
        return calendar.date(byAdding: parts.count == 3 ? .day : .month, value: 1, to: first)
    }
}
