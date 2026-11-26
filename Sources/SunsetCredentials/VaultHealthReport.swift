public import Foundation

/// Local offline password health audit across a vault's entries (roadmap 0092 F): identifies weak passwords (short or
/// low character-class diversity) and passwords reused across multiple entries, without ever sending secrets over the
/// network.
public struct VaultHealthReport: Sendable, Equatable {
    public struct Finding: Sendable, Equatable {
        public let entryID: UUID
        public let fieldID: UUID

        public init(entryID: UUID, fieldID: UUID) {
            self.entryID = entryID
            self.fieldID = fieldID
        }
    }

    public let weak: [Finding]
    public let reused: [Finding]
    public let totalPasswords: Int

    public init(weak: [Finding], reused: [Finding], totalPasswords: Int) {
        self.weak = weak
        self.reused = reused
        self.totalPasswords = totalPasswords
    }

    /// Evaluates every password (`isPassword`) in `entries`, locally.
    public static func analyze(_ entries: [VaultEntry]) -> Self {
        var weak: [Finding] = []
        var byValue: [String: [Finding]] = [:]
        var total = 0

        for entry in entries {
            for section in entry.sections {
                for field in section.fields where isPassword(field) {
                    total += 1
                    let finding = Finding(entryID: entry.id, fieldID: field.id)
                    if isWeak(field.value) { weak.append(finding) }
                    byValue[field.value, default: []].append(finding)
                }
            }
        }
        var reused: [Finding] = []
        for group in byValue.values where group.count > 1 {
            reused.append(contentsOf: group)
        }
        return Self(weak: weak, reused: reused, totalPasswords: total)
    }

    /// A field this report judges: a hidden field named "Password" or "Passphrase" with a value (a login's, a server's,
    /// a Wi-Fi network's). A card's security code or PIN, a licence key or an API secret is hidden but is not one.
    static func isPassword(_ field: EntryField) -> Bool {
        guard field.kind == .concealed, !field.value.isEmpty else { return false }
        let name = field.name.lowercased()
        return name == "password" || name == "passphrase"
    }

    /// True when `password` has fewer than 12 characters or fewer than 2 distinct character classes while under 16 chars.
    public static func isWeak(_ password: String) -> Bool {
        if password.count < 12 { return true }
        var classes = 0
        if password.contains(where: { $0.isLowercase }) { classes += 1 }
        if password.contains(where: { $0.isUppercase }) { classes += 1 }
        if password.contains(where: { $0.isNumber }) { classes += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { classes += 1 }
        return password.count < 16 && classes < 3
    }
}
