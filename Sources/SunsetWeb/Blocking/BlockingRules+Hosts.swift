import Foundation

extension BlockingRules {
    /// A hosts file's lines (StevenBlack's, OISD's hosts form): `0.0.0.0 host …`, each host blocked with its subdomains as
    /// `||host^` is. The machine's own names (`localhost` and its kin) and addresses are never blocked.
    enum Hosts {
        private static let sinks: Set<Substring> = [
            "0.0.0.0", "127.0.0.1", "255.255.255.255", "::", "::1", "0", "fe80::1%lo0"
        ]
        private static let own = Set(
            ("localhost localhost.localdomain local broadcasthost ip6-localhost ip6-loopback ip6-localnet ip6-mcastprefix "
                + "ip6-allnodes ip6-allrouters ip6-allhosts")
                .split(separator: " ").map(String.init)
        )

        /// The hosts a line names, or nil when it is not a hosts line.
        /// - Complexity: O(the line).
        static func hosts(_ line: String) -> [String]? {
            guard let first = line.utf8.first,
                first == UInt8(ascii: ":") || (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains(first)
            else { return nil }
            let content = line.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
            let words = content.split(whereSeparator: \.isWhitespace)
            guard words.count >= 2, sinks.contains(words[0]) else { return nil }
            return words.dropFirst()
                .map { $0.lowercased() }
                .filter { !own.contains($0) && isSite($0) && !isAddress($0) }
        }

        /// The rule blocking `host` and its subdomains.
        static func rule(_ host: String) -> Rule? {
            Network.urlFilter(Substring("||\(host)^"))
                .map {
                    Rule(trigger: Rule.Trigger(urlFilter: $0), action: Rule.Action(type: "block"))
                }
        }

        private static func isAddress(_ name: String) -> Bool {
            name.utf8.allSatisfy { $0 == UInt8(ascii: ".") || (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains($0) }
        }
    }

    /// A host name as a list names a site: ASCII letters, digits, `-` and `_`, in labels separated by dots, none empty; no
    /// regular expression (`/^news\d+\.example/`) nor AdGuard's `example.*`, which WebKit's `if-domain` cannot take.
    /// - Complexity: O(the name).
    static func isSite(_ name: some StringProtocol) -> Bool {
        var label = 0
        var last: UInt8 = 0
        for byte in name.utf8 {
            switch byte {
                case UInt8(ascii: "."):
                    guard label > 0, last != UInt8(ascii: "-") else { return false }
                    label = 0
                case UInt8(ascii: "a") ... UInt8(ascii: "z"), UInt8(ascii: "A") ... UInt8(ascii: "Z"),
                    UInt8(ascii: "0") ... UInt8(ascii: "9"), UInt8(ascii: "_"):
                    label += 1
                case UInt8(ascii: "-"):
                    guard label > 0 else { return false }
                    label += 1
                default:
                    return false
            }
            last = byte
        }
        return label > 0 && last != UInt8(ascii: "-")
    }

    /// Every name a site (`~` for a site left alone): one that is not leaves the whole rule out, since dropping one of
    /// `~a.com,b.*` would hide or block more than the list says.
    static func areSites(_ names: [some StringProtocol]) -> Bool {
        names.allSatisfy { isSite($0.hasPrefix("~") ? $0.dropFirst() : $0[...]) }
    }

    /// A `#` line that is a comment (a hosts file's, uBlock's), not element hiding: `#` and its run followed by a space or
    /// nothing (`# Title`, `### Version #`, `#####`); `##.ad` and `###id` stay element hiding.
    static func isComment(_ line: String) -> Bool {
        guard line.hasPrefix("#") else { return false }
        let rest = line.drop { $0 == "#" }
        return rest.first.map(\.isWhitespace) ?? true
    }
}
