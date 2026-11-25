internal import AemiJSONCore
import Foundation
internal import OrderedCollections

/// Plain JSON imports for authenticator apps (roadmap 0093 C / t102): Aegis Authenticator, 2FAS Authenticator, and
/// andOTP. All three parse strictly via `AemiJSON` (RFC 8259, no duplicate keys, max depth 32) and feed one table-driven
/// extractor (`extractRecord`) so validation, error handling, and entry construction stay uniform with zero duplication.
extension LoginImport {
    typealias JSONObject = OrderedDictionary<String, JSONValue>

    private struct FieldMap {
        let nestedOTPKey: String?
        let typeKey: String
        let secretInOTP: Bool
        let issuerKey: String
        let fallbackIssuerKey: String?
        let accountKey: String
        let fallbackAccountKey: String?
        let algorithmKey: String
        let tagsKey: String?
    }

    private static let aegisMap = FieldMap(
        nestedOTPKey: "info",
        typeKey: "type",
        secretInOTP: true,
        issuerKey: "issuer",
        fallbackIssuerKey: nil,
        accountKey: "name",
        fallbackAccountKey: nil,
        algorithmKey: "algo",
        tagsKey: "groups"
    )

    private static let twoFASMap = FieldMap(
        nestedOTPKey: "otp",
        typeKey: "tokenType",
        secretInOTP: false,
        issuerKey: "issuer",
        fallbackIssuerKey: "name",
        accountKey: "account",
        fallbackAccountKey: "label",
        algorithmKey: "algorithm",
        tagsKey: nil
    )

    private static let andOTPMap = FieldMap(
        nestedOTPKey: nil,
        typeKey: "type",
        secretInOTP: false,
        issuerKey: "issuer",
        fallbackIssuerKey: nil,
        accountKey: "label",
        fallbackAccountKey: nil,
        algorithmKey: "algorithm",
        tagsKey: "tags"
    )

    static func parseStrictJSON(_ text: String) throws(Failure) -> JSONValue {
        let options = JSONParseOptions(validation: .strict, duplicateKeys: .throwError, maxDepth: 32)
        guard let root = try? JSONValue(parsing: text, options: options) else { throw .notAnExport }
        return root
    }

    /// Reads an Aegis Authenticator JSON export (`{ "db": { "entries": [...] } }`).
    public static func readAegis(_ text: String) throws(Failure) -> Self {
        guard case .object(let top) = try parseStrictJSON(text) else { throw .notAnExport }
        return try readAegisObject(top)
    }

    /// Reads a 2FAS Authenticator `.2fas` JSON export (`{ "services": [...] }`).
    public static func read2FAS(_ text: String) throws(Failure) -> Self {
        guard case .object(let top) = try parseStrictJSON(text) else { throw .notAnExport }
        return try read2FASObject(top)
    }

    /// Reads an andOTP plain JSON export (top-level array of authenticator objects).
    public static func readAndOTP(_ text: String) throws(Failure) -> Self {
        guard case .array(let list) = try parseStrictJSON(text) else { throw .notAnExport }
        return try readAndOTP(list)
    }

    static func readAegisObject(_ top: JSONObject) throws(Failure) -> Self {
        if case .string? = top["db"] { throw .encrypted }
        guard case .object(let db)? = top["db"], case .array(let items)? = db["entries"] else {
            throw .notAnExport
        }
        return importAuthenticatorItems(items, source: .aegis, map: aegisMap, groups: [:])
    }

    static func read2FASObject(_ top: JSONObject) throws(Failure) -> Self {
        if let enc = jsonText(top["servicesEncrypted"]), !enc.isEmpty { throw .encrypted }
        guard case .array(let services)? = top["services"] else { throw .notAnExport }
        return importAuthenticatorItems(services, source: .twoFAS, map: twoFASMap, groups: folderNames(top["groups"]))
    }

    static func readAndOTP(_ list: [JSONValue]) throws(Failure) -> Self {
        let hasSecretObject = list.contains { item in
            if case .object(let obj) = item, obj["secret"] != nil { return true }
            return false
        }
        guard hasSecretObject else { throw .notAnExport }
        return importAuthenticatorItems(list, source: .andOTP, map: andOTPMap, groups: [:])
    }

    // MARK: - Shared extractor & normalizer

    private static func importAuthenticatorItems(
        _ items: [JSONValue],
        source: Source,
        map: FieldMap,
        groups: [String: String]
    ) -> Self {
        var entries: [VaultEntry] = []
        var skipped: [Skipped] = []
        var warnings: [Warning] = []
        for index in items.indices {
            switch decodeAuthenticatorItem(items[index], source: source, map: map, groups: groups) {
                case .entry(let entry): entries.append(entry)
                case .skip(let reason): skipped.append(Skipped(row: index + 1, reason: reason))
                case .warn(let reason): warnings.append(Warning(row: index + 1, reason: reason))
            }
        }
        return Self(source: source, entries: entries, skipped: skipped, warnings: warnings, duplicates: 0)
    }

    private enum ItemOutcome {
        case entry(VaultEntry)
        case skip(SkipReason)
        case warn(WarningReason)
    }

    private static func decodeAuthenticatorItem(
        _ raw: JSONValue,
        source: Source,
        map: FieldMap,
        groups: [String: String]
    ) -> ItemOutcome {
        guard case .object(let obj) = raw, let otp = otpSection(in: obj, source: source, map: map) else {
            return .skip(.unknownKind)
        }
        let rawType = (jsonText((source == .aegis ? obj : otp)[map.typeKey]) ?? "totp").lowercased()
        guard let kind = otpKind(rawType) else { return .skip(.unknownKind) }

        let primary = source == .twoFAS ? otp : obj
        let issuer = jsonText(primary[map.issuerKey]) ?? map.fallbackIssuerKey.flatMap { jsonText(obj[$0]) } ?? ""
        let account =
            jsonText(primary[map.accountKey]) ?? map.fallbackAccountKey.flatMap { jsonText(primary[$0]) } ?? ""
        let secret = jsonText((map.secretInOTP ? otp : obj)["secret"])

        guard
            let uri = buildURI(
                kind: kind,
                secretText: secret,
                issuer: issuer,
                account: account,
                otp: otp,
                algoKey: map.algorithmKey
            )
        else { return .warn(.unreadableCode) }

        let title = !issuer.isEmpty ? issuer : (!account.isEmpty ? account : "Authenticator Code")
        var entry = EntryTemplate.login.makeEntry(title: title)
        if !account.isEmpty, let id = entry.field(named: "Username")?.id { entry.set(id, account) }
        if let id = entry.field(named: "One-Time Code")?.id { entry.set(id, uri.uri) }
        entry.note = jsonText(obj["note"]) ?? ""
        if case .bool(true)? = obj["favorite"] { entry.isFavorite = true }
        entry.folder = jsonText(obj["groupId"]).flatMap { groups[$0] }
        if let tagsKey = map.tagsKey, case .array(let list)? = obj[tagsKey] {
            entry.tags = list.compactMap(jsonText).filter { !$0.isEmpty }
        }
        return .entry(entry)
    }

    private static func otpSection(in obj: JSONObject, source: Source, map: FieldMap) -> JSONObject? {
        guard let key = map.nestedOTPKey else { return obj }
        if case .object(let nested)? = obj[key] { return nested }
        return source == .aegis ? nil : [:]
    }

    private static func otpKind(_ raw: String) -> OneTimeCodeURI.Kind? {
        switch raw {
            case "totp": .totp
            case "hotp": .hotp
            case "steam": .steam
            default: nil
        }
    }

    private static func buildURI(
        kind: OneTimeCodeURI.Kind,
        secretText: String?,
        issuer: String,
        account: String,
        otp: JSONObject,
        algoKey: String
    ) -> OneTimeCodeURI? {
        guard let secretText, let secret = try? Base32.decode(secretText), !secret.isEmpty else { return nil }
        let algoName = (jsonText(otp[algoKey]) ?? "sha1").lowercased().replacing("hmac", with: "")
            .filter { $0.isLetter || $0.isNumber }
        guard let algorithm = OneTimeCode.Algorithm(rawValue: algoName.isEmpty ? "sha1" : algoName) else { return nil }
        let digits = kind == .steam ? 5 : (otpInt(otp["digits"]) ?? 6)
        let period = otpInt(otp["period"]) ?? 30
        guard kind == .steam || OneTimeCode.Parameters(digits: digits, period: period).isValid else { return nil }
        var uri = OneTimeCodeURI(
            kind: kind,
            issuer: issuer.isEmpty ? nil : issuer,
            account: account,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            counter: otpUInt64(otp["counter"]) ?? 0
        )
        uri.period = period
        return uri
    }

    private static func otpInt(_ value: JSONValue?) -> Int? {
        switch value {
            case .int(let n)?: Int(exactly: n)
            case .string(let s)?: Int(s.trimmingCharacters(in: .whitespaces))
            default: nil
        }
    }

    private static func otpUInt64(_ value: JSONValue?) -> UInt64? {
        switch value {
            case .int(let n)? where n >= 0: UInt64(n)
            case .string(let s)?: UInt64(s.trimmingCharacters(in: .whitespaces))
            default: nil
        }
    }
}
