internal import AemiJSONCore
import Foundation
internal import OrderedCollections

/// A field's value in a 1Password export: an object with one key naming its type (`concealed`, `string`, `totp`,
/// `date`, `monthYear`, `email`, `address`, `sshKey`, `file`, …), as the vault's text of the field's kind.
enum OnePasswordValue {
    case plain(String, FieldKind)
    /// An attachment, by its document's id.
    case file(String)

    var text: String {
        switch self {
            case .plain(let text, _): text
            case .file: ""
        }
    }

    var kind: FieldKind {
        switch self {
            case .plain(_, let kind): kind
            case .file: .file
        }
    }

    init?(_ value: OrderedDictionary<String, JSONValue>) {
        guard let type = value.keys.first, let content = value[type] else { return nil }
        let text = LoginImport.jsonText(content) ?? ""
        switch type {
            case "concealed": self = .plain(text, .concealed)
            case "totp": self = .plain(text, .oneTimeCode)
            case "url": self = .plain(text, .url)
            case "phone": self = .plain(text, .phone)
            case "creditCardNumber": self = .plain(text, .cardNumber)
            case "string", "menu", "creditCardType", "gender":
                self = .plain(text, text.contains("\n") ? .multiline : .text)
            case "email": self = .plain(Self.member(content, "email_address") ?? text, .email)
            case "date":
                guard case .int(let seconds) = content else { return nil }
                self = .plain(Self.day(seconds), .date)
            case "monthYear":
                // YYYYMM, as 1Password keeps an expiry.
                guard case .int(let month) = content, month > 100 else { return nil }
                self = .plain(String(format: "%04d-%02d", month / 100, month % 100), .monthYear)
            case "address":
                let parts = ["street", "city", "state", "zip", "country"].compactMap { Self.member(content, $0) }
                self = .plain(parts.filter { !$0.isEmpty }.joined(separator: "\n"), .address)
            case "sshKey": self = .plain(Self.member(content, "privateKey") ?? "", .sshKey)
            case "file": self = .file(Self.member(content, "documentId") ?? "")
            default:
                guard !text.isEmpty else { return nil }
                self = .plain(text, .text)
        }
    }

    private static func member(_ value: JSONValue, _ key: String) -> String? {
        guard case .object(let object) = value else { return nil }
        return LoginImport.jsonText(object[key])
    }

    /// A day as the vault writes it (2030-04-30), from seconds since 1970, in UTC.
    private static func day(_ seconds: Int64) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let parts = calendar.dateComponents(
            [.year, .month, .day],
            from: Date(timeIntervalSince1970: TimeInterval(seconds))
        )
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
