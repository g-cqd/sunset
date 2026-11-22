internal import Darwin

/// Whether an internet address is one anyone on the internet could be reached at: not this Mac, the local network, a
/// link, or a range kept for documentation, testing or multicast (RFC 6890's special-purpose registries). What a page asks
/// Sunset to fetch for it may only go to those (the outside audit's HIGH-01, 2026-11-22).
package enum PublicAddress {
    /// Whether `bytes` (4 for IPv4, 16 for IPv6) is such an address.
    package static func isPublic(_ bytes: [UInt8]) -> Bool {
        switch bytes.count {
            case 4: isPublicV4(bytes[0], bytes[1], bytes[2])
            case 16: isPublicV6(bytes)
            default: false
        }
    }

    private static func isPublicV4(_ a: UInt8, _ b: UInt8, _ c: UInt8) -> Bool {
        switch a {
            case 0, 10, 127: return false
            case 100 where b & 0xC0 == 64: return false  // shared address space (carrier NAT)
            case 169 where b == 254: return false  // link-local
            case 172 where b & 0xF0 == 16: return false
            case 192 where b == 168 || (b == 0 && (c == 0 || c == 2)) || (b == 88 && c == 99): return false
            case 198 where b & 0xFE == 18 || (b == 51 && c == 100): return false  // benchmarking, documentation
            case 203 where b == 0 && c == 113: return false
            case 224...: return false  // multicast, reserved, broadcast
            default: return true
        }
    }

    private static func isPublicV6(_ bytes: [UInt8]) -> Bool {
        let (a, b) = (bytes[0], bytes[1])
        if bytes[0 ..< 10].allSatisfy({ $0 == 0 }) {
            // IPv4-mapped (::ffff:a.b.c.d) is the IPv4 address; the rest of ::/80 (::, ::1, IPv4-compatible) is not public.
            guard bytes[10] == 0xFF, bytes[11] == 0xFF else { return false }
            return isPublicV4(bytes[12], bytes[13], bytes[14])
        }
        if bytes[0 ..< 12].elementsEqual([0, 0x64, 0xFF, 0x9B, 0, 0, 0, 0, 0, 0, 0, 0]) {
            return isPublicV4(bytes[12], bytes[13], bytes[14])  // NAT64: the IPv4 address it stands for
        }
        if a == 0x01, b == 0, bytes[2 ..< 8].allSatisfy({ $0 == 0 }) { return false }  // discard-only
        if a == 0x20, b == 0x01, bytes[2] & 0xFE == 0 || (bytes[2] == 0x0D && bytes[3] == 0xB8) { return false }
        if a == 0x20, b == 0x02 { return false }  // 6to4
        if a & 0xFE == 0xFC || a == 0xFF { return false }  // unique local, multicast
        if a == 0xFE, b & 0x80 == 0x80 { return false }  // link-local and site-local (fe80::/10, fec0::/10)
        return true
    }

    /// The address `host` is written as (`127.0.0.1`, `::1`, `[::1]`), nil when it is a name.
    package static func literal(_ host: String) -> [UInt8]? {
        var text = host
        if text.hasPrefix("["), text.hasSuffix("]") { text = String(text.dropFirst().dropLast()) }
        if let zone = text.firstIndex(of: "%") { text = String(text[..<zone]) }
        var v4 = in_addr()
        if inet_pton(AF_INET, text, &v4) == 1 { return withUnsafeBytes(of: &v4) { Array($0) } }
        var v6 = in6_addr()
        if inet_pton(AF_INET6, text, &v6) == 1 { return withUnsafeBytes(of: &v6) { Array($0) } }
        return nil
    }

    /// The addresses `host` resolves to now; empty when it does not resolve. Blocks: call it off the main thread.
    package static func resolve(_ host: String) -> [[UInt8]] {
        var hints = addrinfo()
        hints.ai_socktype = SOCK_STREAM
        var list: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &list) == 0 else { return [] }
        defer { freeaddrinfo(list) }
        var found: [[UInt8]] = []
        var next = list
        while let entry = next {
            if let address = entry.pointee.ai_addr {
                switch entry.pointee.ai_family {
                    case AF_INET:
                        found.append(
                            address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                                bytes(of: $0.pointee.sin_addr)
                            }
                        )
                    case AF_INET6:
                        found.append(
                            address.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                                bytes(of: $0.pointee.sin6_addr)
                            }
                        )
                    default: break
                }
            }
            next = entry.pointee.ai_next
        }
        return found
    }

    private static func bytes<T>(of value: T) -> [UInt8] {
        var copy = value
        return withUnsafeBytes(of: &copy) { Array($0) }
    }
}
