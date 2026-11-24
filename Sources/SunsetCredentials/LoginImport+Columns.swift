/// The columns of the CSV that browsers and password managers export, found by their headers (roadmap 0095 D). A header is read without its
/// case or anything that is not a letter or a digit (`login_uri`, `Login URI` and `loginuri` are one), and each of the names below is the
/// one of an export of that program, as remembered: a file's columns need not be in an order, nor all be there.
extension LoginImport {
    enum Role: CaseIterable {
        case title, url, username, password, notes, code, folder, favorite, tags, type, archived

        var names: [String] {
            switch self {
                case .title: ["title", "name"]
                case .url: ["url", "website", "loginuri", "uri", "weburl"]
                case .username: ["username", "loginusername", "user", "login", "loginname"]
                case .password: ["password", "loginpassword", "pass"]
                case .notes: ["notes", "note", "extra"]
                case .code: ["otpauth", "logintotp", "totp", "otp"]
                case .folder: ["folder", "grouping", "group"]
                case .favorite: ["favorite", "favourite", "fav"]
                case .tags: ["tags"]
                case .type: ["type"]
                case .archived: ["archived"]
            }
        }
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
