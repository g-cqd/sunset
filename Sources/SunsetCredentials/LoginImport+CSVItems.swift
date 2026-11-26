/// CSV rows that are not logins (roadmap 0095 D / t104): a secure note (`type` = `note`, `securenote`) becomes a
/// Secure Note entry with its title and text; a card (`type` = `card`, `creditcard`) becomes a Card entry from the
/// card columns (cardholder, number, expiry as `MM/YY`, `MM/YYYY`, `YYYY-MM` or separate month and year, security
/// code). Any other kind is left out and said, never guessed.
extension LoginImport {
    struct CSVItem {
        let entry: VaultEntry
        let expiryUnreadable: Bool
    }

    /// The entry a non-login row of kind `kind` makes, or nil when the kind is not one Sunset reads.
    static func csvItem(kind: String, cell: (Role) -> String, token: (Role) -> String) -> CSVItem? {
        let title = cell(.title)
        switch normalized(kind) {
            case "note", "notes", "securenote":
                let text = cell(.notes)
                guard !title.isEmpty || !text.isEmpty else { return nil }
                var entry = EntryTemplate.secureNote.makeEntry(title: title.isEmpty ? "Note" : title)
                entry.note = text
                return CSVItem(entry: entry, expiryUnreadable: false)
            case "card", "creditcard", "paymentcard":
                var entry = EntryTemplate.card.makeEntry(title: title.isEmpty ? "Card" : title)
                put("Cardholder", cell(.cardholder), in: &entry)
                put("Number", token(.cardNumber).filter { !$0.isWhitespace }, in: &entry)
                put("Security Code", token(.cardCode), in: &entry)
                let expiry = cardExpiry(
                    combined: token(.cardExpiry),
                    month: token(.cardExpMonth),
                    year: token(.cardExpYear)
                )
                put("Expiry", expiry.value ?? "", in: &entry)
                entry.note = cell(.notes)
                return CSVItem(entry: entry, expiryUnreadable: expiry.unreadable)
            default:
                return nil
        }
    }

    /// A card's expiry from one column (`MM/YY`, `MM/YYYY`, `YYYY-MM`) or a month and a year; unreadable when given
    /// but not one.
    private static func cardExpiry(combined: String, month: String, year: String) -> (value: String?, unreadable: Bool)
    {
        if !combined.isEmpty {
            let parts = combined.split(whereSeparator: { $0 == "/" || $0 == "-" || $0 == "." }).map(String.init)
            guard parts.count == 2 else { return (nil, true) }
            let value =
                parts[0].count == 4
                ? expiry(month: parts[1], year: parts[0]) : expiry(month: parts[0], year: parts[1])
            return (value, value == nil)
        }
        guard !month.isEmpty || !year.isEmpty else { return (nil, false) }
        let value = expiry(month: month, year: year)
        return (value, value == nil)
    }
}
