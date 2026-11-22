import Foundation

/// Reading a line of the shipped templates' table (`EntryTemplate.table`).
extension EntryTemplate {
    static func read(line: String) -> Self? {
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4, let id = UUID(uuidString: "5E7C0000-0000-4000-8000-0000000000\(parts[0])") else {
            return nil
        }
        let fields = parts[3].split(separator: ";")
            .compactMap { field(String($0).trimmingCharacters(in: .whitespaces)) }
        return EntryTemplate(
            id: id,
            name: parts[1],
            symbol: parts[2],
            sections: fields.isEmpty ? [] : [EntrySection(name: parts[1], fields: fields)]
        )
    }

    /// `Name:kind/constraint`.
    private static func field(_ text: String) -> EntryField? {
        guard let colon = text.firstIndex(of: ":") else { return nil }
        let name = String(text[..<colon])
        let rest = text[text.index(after: colon)...].split(separator: "/", maxSplits: 1).map(String.init)
        guard let kindText = rest.first, let kind = kind(kindText) else { return nil }
        return EntryField(name: name, kind: kind, constraints: rest.dropFirst().compactMap(constraint))
    }

    private static func kind(_ text: String) -> FieldKind? {
        if text.hasPrefix("choice("), text.hasSuffix(")") {
            return .choice(text.dropFirst(7).dropLast().split(separator: ",").map(String.init))
        }
        // A kind without options is written as it is named.
        let plain: [FieldKind] = [
            .text, .multiline, .concealed, .oneTimeCode, .url, .email, .phone, .number, .money, .date, .monthYear,
            .time,
            .toggle, .cardNumber, .reference, .file, .sshKey, .address
        ]
        return plain.first { String(describing: $0) == text }
    }

    private static func constraint(_ text: String) -> FieldConstraint? {
        func bounds(_ prefix: String) -> (Int, Int)? {
            let numbers = text.dropFirst(prefix.count).split(separator: "-").compactMap { Int($0) }
            return numbers.count == 2 && numbers[0] <= numbers[1] ? (numbers[0], numbers[1]) : nil
        }
        switch text {
            case "luhn": return .luhn
            case "future": return .inTheFuture
            case _ where text.hasPrefix("length"): return bounds("length").map { .length($0.0 ... $0.1) }
            case _ where text.hasPrefix("range"): return bounds("range").map { .range(Double($0.0) ... Double($0.1)) }
            default: return nil
        }
    }
}
