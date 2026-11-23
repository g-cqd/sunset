import Foundation

extension FieldKind {
    /// Whether `value` fits this kind as it is. Empty fits every kind; text, a secret and a single-line kind lose line
    /// breaks; the others take only what they show and check.
    public func fit(_ value: String) -> FieldFit {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .fits }
        if let why = Self.multilineKinds.contains(self) ? nil : (value.contains("\n") ? "it has line breaks" : nil) {
            return .loses(why)
        }
        return problem(trimmed).map(FieldFit.loses) ?? .fits
    }

    private static let multilineKinds: Set<FieldKind> = [.multiline, .sshKey, .address]

    /// Why `value` does not fit this kind; nil when it does.
    private func problem(_ value: String) -> String? {
        switch self {
            case .number: Double(value) == nil ? "it is not a number" : nil
            case .money: Double(value.filter { !"$€£¥ ".contains($0) }) == nil ? "it is not an amount" : nil
            case .date: value.wholeMatch(of: /\d{4}-\d{2}-\d{2}/) == nil ? "it is not a date (2030-04-30)" : nil
            case .monthYear: value.wholeMatch(of: /\d{4}-\d{2}/) == nil ? "it is not a month (2030-04)" : nil
            case .time: value.wholeMatch(of: /\d{1,2}:\d{2}(:\d{2})?/) == nil ? "it is not a time (09:30)" : nil
            case .url: Self.isAddress(value) ? nil : "it is not a web address"
            case .email: value.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) == nil ? "it is not an email address" : nil
            case .phone: Self.isPhone(value) ? nil : "it is not a phone number"
            case .toggle: ["true", "false"].contains(value) ? nil : "it is not on or off"
            case .choice(let options): options.contains(value) ? nil : "it is not one of the choices"
            case .multipleChoice(let options):
                value.split(separator: ",").allSatisfy { options.contains($0.trimmingCharacters(in: .whitespaces)) }
                    ? nil : "it is not among the choices"
            case .cardNumber:
                value.allSatisfy { $0.isNumber || $0 == " " || $0 == "-" } ? nil : "it is not a card number"
            case .oneTimeCode: OneTimeCodeField(value) == nil ? "it is not a one-time code's secret" : nil
            default: nil
        }
    }

    private static func isPhone(_ value: String) -> Bool {
        value.allSatisfy { $0.isNumber || " +-().".contains($0) } && value.contains(where: \.isNumber)
    }

    /// A web address, with its scheme or without ("example.com"): a host with a dot, no spaces.
    private static func isAddress(_ value: String) -> Bool {
        guard !value.contains(" ") else { return false }
        let address = URL(string: value.contains("://") ? value : "https://" + value)
        return address?.host()?.contains(".") == true
    }
}
