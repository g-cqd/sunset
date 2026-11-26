/// The columns of the CSV that browsers and password managers export, found by their headers (roadmap 0095 D). A header is read without its
/// case or anything that is not a letter or a digit (`login_uri`, `Login URI` and `loginuri` are one), and each of the names below is the
/// one of an export of that program, as remembered: a file's columns need not be in an order, nor all be there.
extension LoginImport {
    enum Role: CaseIterable {
        case title, url, username, password, notes, code, folder, favorite, tags, type, archived
        /// A card row's columns (roadmap 0095 D / t104): read only for rows whose `type` is a card.
        case cardholder, cardNumber, cardExpiry, cardExpMonth, cardExpYear, cardCode

        var names: [String] {
            Self.table[self] ?? []
        }

        /// Each role's header names, one line a role, in `allCases` order.
        private static let table = Dictionary(
            uniqueKeysWithValues: zip(
                allCases,
                """
                title name
                url website loginuri uri weburl
                username loginusername user login loginname
                password loginpassword pass
                notes note extra
                otpauth logintotp totp otp
                folder grouping group
                favorite favourite fav
                tags
                type
                archived
                cardholder cardholdername nameoncard cardname
                cardnumber ccnumber number
                expiry expirationdate expiration expires cardexpiry
                expmonth expirationmonth cardexpmonth
                expyear expirationyear cardexpyear
                cvv cvc cvv2 securitycode cardcode cardcvv
                """
                .split(separator: "\n").map { $0.split(separator: " ").map(String.init) }
            )
        )
    }

    /// The column of each role the header row has (the first, when two names are there).
    static func columns(of header: [String]) -> [Role: Int] {
        let names = header.map(normalized)
        var found: [Role: Int] = [:]
        for role in Role.allCases {
            if let index = names.firstIndex(where: { role.names.contains($0) }) { found[role] = index }
        }
        return found
    }

    static func normalized(_ header: String) -> String {
        String(header.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    /// Whose export the header row looks like: by the columns only that program writes, else by the shape; `generic` when it is none.
    static func source(of header: [String]) -> Source {
        let names = Set(header.map(normalized))
        if names.contains("loginuri") || names.contains("reprompt") { return .bitwarden }
        if names.contains("httprealm") || names.contains("formactionorigin") { return .firefox }
        if names.contains("archived") || names.contains("tags") { return .onePassword }
        if names.contains("otpauth"), names.contains("title") { return .applePasswords }
        if names.contains("grouping") || names.contains("extra") { return .lastPass }
        if names.contains("name"), names.contains("url"), names.contains("note") { return .chrome }
        return .generic
    }
}
