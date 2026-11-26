/// `ssh:` addresses (draft-ietf-secsh-scp-sftp-ssh-uri-04 §3.3: `ssh://[userinfo[;c-param,…]@]host[:port]path-abempty`),
/// held to what a user name, a host name and a port are: the system hands the address to its ssh handler, which runs `ssh`
/// with it, so nothing in it may read as an option (a leading `-`) or carry blanks or controls, percent-encoded or not.
extension HyperlinkPolicy {
    static func opensSSH(_ rest: Substring) -> Bool {
        guard rest.hasPrefix("//") else { return false }
        let afterSlashes = rest.dropFirst(2)
        let authority = afterSlashes.prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        let path = afterSlashes.dropFirst(authority.count)
        guard let decodedPath = percentDecoded(path), decodedPath.allSatisfy({ $0 > 0x20 && $0 != 0x7F }) else {
            return false
        }
        var hostAndPort = authority[...]
        if let at = authority.lastIndex(of: "@") {
            guard isSSHInfo(authority[authority.startIndex ..< at]) else { return false }
            hostAndPort = authority[authority.index(after: at)...]
        }
        var host = hostAndPort
        if let colon = hostAndPort.lastIndex(of: ":"), !hostAndPort.hasSuffix("]") {
            let port = hostAndPort[hostAndPort.index(after: colon)...]
            guard !port.isEmpty, port.utf8.count <= 5, port.utf8.allSatisfy(isDigit) else { return false }
            host = hostAndPort[hostAndPort.startIndex ..< colon]
        }
        return isSSHHost(host)
    }

    /// The user, and the connection parameters after `;` (`name=value`, letters, digits and `-`).
    private static func isSSHInfo(_ info: Substring) -> Bool {
        let parts = info.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        guard let user = percentDecoded(parts[0]), !user.isEmpty, user.first != UInt8(ascii: "-"),
            user.allSatisfy(isUnreserved)
        else { return false }
        guard parts.count == 2 else { return true }
        return parts[1].split(separator: ",", omittingEmptySubsequences: false)
            .allSatisfy { parameter in
                let pair = parameter.split(separator: "=", omittingEmptySubsequences: false)
                return pair.count == 2
                    && pair.allSatisfy {
                        !$0.isEmpty && $0.utf8.allSatisfy { isUnreserved($0) && $0 != 0x2E && $0 != 0x5F && $0 != 0x7E }
                    }
            }
    }

    /// A host name (letters, digits, `-`, `.`, `_`, not starting with `-`), or an IP literal in brackets.
    private static func isSSHHost(_ host: Substring) -> Bool {
        if host.hasPrefix("[") {
            let inner = host.dropFirst().dropLast()
            return host.hasSuffix("]") && !inner.isEmpty
                && inner.utf8.allSatisfy { hexValue($0) != nil || $0 == UInt8(ascii: ":") || $0 == UInt8(ascii: ".") }
        }
        guard let name = percentDecoded(host), let first = name.first, first != UInt8(ascii: "-") else { return false }
        return name.allSatisfy { isUnreserved($0) && $0 != UInt8(ascii: "~") }
    }

    /// RFC 3986's unreserved characters: letters, digits, `-`, `.`, `_`, `~`.
    private static let unreserved = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~".utf8)

    private static func isUnreserved(_ byte: UInt8) -> Bool {
        unreserved.contains(byte)
    }

    /// The bytes `text` stands for, its `%XX` escapes decoded; nil when an escape is malformed.
    private static func percentDecoded(_ text: Substring) -> [UInt8]? {
        let bytes = Array(text.utf8)
        var out: [UInt8] = []
        out.reserveCapacity(bytes.count)
        var index = 0
        while index < bytes.count {
            guard bytes[index] == UInt8(ascii: "%") else {
                out.append(bytes[index])
                index += 1
                continue
            }
            guard index + 2 < bytes.count, let high = hexValue(bytes[index + 1]), let low = hexValue(bytes[index + 2])
            else { return nil }
            out.append(high << 4 | low)
            index += 3
        }
        return out
    }

    private static func isDigit(_ byte: UInt8) -> Bool {
        byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
    }

    private static func hexValue(_ byte: UInt8) -> UInt8? {
        switch byte {
            case UInt8(ascii: "0") ... UInt8(ascii: "9"): byte - UInt8(ascii: "0")
            case UInt8(ascii: "a") ... UInt8(ascii: "f"): byte - UInt8(ascii: "a") + 10
            case UInt8(ascii: "A") ... UInt8(ascii: "F"): byte - UInt8(ascii: "A") + 10
            default: nil
        }
    }
}
