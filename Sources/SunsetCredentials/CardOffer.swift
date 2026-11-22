import Foundation

/// What a page's card field is offered (roadmap 0094 F): every card of the vault with a number (cards are not tied to a
/// site), by title; its values as a form wants them: the number's digits, the holder, the expiry's month (two digits) and
/// year (four), the security code.
public struct CardOffer: Sendable {
    public struct Values: Equatable, Sendable {
        public var number = ""
        public var name = ""
        public var month = ""
        public var year = ""
        public var code = ""
    }

    public let entry: VaultEntry
    public let values: Values

    /// The number's last four digits, the way a card is shown without its number.
    public var lastFour: String {
        String(values.number.suffix(4))
    }

    public static func offered(_ entries: [VaultEntry]) -> [CardOffer] {
        entries.compactMap { entry -> CardOffer? in
            let fields = entry.sections.flatMap(\.fields)
            let number = fields.first { $0.kind == .cardNumber }?.value.filter(\.isNumber) ?? ""
            guard number.count >= 12 else { return nil }
            let expiry = expiry(fields.first { $0.kind == .monthYear }?.value ?? "")
            let values = Values(
                number: number,
                name: entry.field(named: "Cardholder")?.value ?? "",
                month: expiry.month,
                year: expiry.year,
                code: entry.field(named: "Security Code")?.value ?? ""
            )
            return CardOffer(entry: entry, values: values)
        }
        .sorted { $0.entry.title.localizedStandardCompare($1.entry.title) == .orderedAscending }
    }

    /// An expiry however written ("2031-04", "04/31", "4/2031"): its month on two digits, its year on four.
    static func expiry(_ text: String) -> (month: String, year: String) {
        let parts = text.split { !$0.isNumber }.map(String.init)
        guard parts.count == 2 else { return ("", "") }
        let (month, year) = parts[0].count == 4 ? (parts[1], parts[0]) : (parts[0], parts[1])
        let fullYear = year.count == 2 ? "20" + year : year
        return (month.count == 1 ? "0" + month : month, fullYear)
    }
}
