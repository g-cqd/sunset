/// Which links may be opened (ADR-0010). Opening is always the user's gesture; this says whether the address is one a terminal opens at all: web, mail and
/// ssh addresses, and files on this machine.
public enum HyperlinkPolicy {
    public static func opens(_ address: String, localHost: String) -> Bool {
        guard let colon = address.firstIndex(of: ":"), colon != address.startIndex else { return false }
        let scheme = address[address.startIndex ..< colon].lowercased()
        let rest = address[address.index(after: colon)...]
        guard !rest.isEmpty else { return false }
        switch scheme {
            case "http", "https": return rest.hasPrefix("//") && rest.count > 2
            case "mailto": return true
            case "ssh": return rest.hasPrefix("//") && rest.count > 2
            case "file":
                guard rest.hasPrefix("//") else { return false }
                let authority = rest.dropFirst(2).prefix { $0 != "/" }.lowercased()
                return authority.isEmpty || authority == "localhost" || authority == localHost.lowercased()
            default: return false
        }
    }
}
