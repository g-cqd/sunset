package import Foundation

/// CFNetwork's cookie jar (`*.binarycookies`), read: how Sunset's cookies reach Sunset WebKit, which sets them through
/// its own WebKit, never by sharing WebKit's files. The format is Apple's and undocumented; as read here (and checked
/// against a jar WebKit wrote, `BinaryCookiesTests`):
///
/// - "cook", a page count and each page's size (big-endian), then the pages;
/// - a page: 0x00000100, a cookie count and each cookie's offset in the page (little-endian);
/// - a cookie (little-endian): its size, a version, its flags (secure 0x1, HttpOnly 0x4, SameSite=Lax 0x8, Strict 0x10,
///   host-only 0x20), then the offsets of its domain, name, path and value (C strings in the record), and at 0x28 its
///   expiry and creation (seconds since 2001).
///
/// Every offset is checked against its record: a cut or altered jar is refused, never read past its end.
package enum BinaryCookies {
    package struct Unreadable: Error, Equatable {}

    package enum SameSite: Equatable, Sendable { case lax, strict }

    package struct Cookie: Equatable, Sendable {
        package var domain: String
        package var name: String
        package var path: String
        package var value: String
        package var expires: Date
        package var secure: Bool
        package var httpOnly: Bool
        package var hostOnly: Bool
        package var sameSite: SameSite?
    }

    /// Every cookie of a jar, in its order.
    package static func read(_ data: Data) throws(Unreadable) -> [Cookie] {
        let bytes = [UInt8](data)
        guard bytes.count >= 8, bytes[0 ..< 4].elementsEqual("cook".utf8) else { throw Unreadable() }
        let pages = Int(try big(bytes, 4))
        var sizes: [Int] = []
        for page in 0 ..< pages { sizes.append(Int(try big(bytes, 8 + page * 4))) }
        var start = 8 + pages * 4
        var cookies: [Cookie] = []
        for size in sizes {
            guard size >= 8, start + size <= bytes.count else { throw Unreadable() }
            cookies += try page(Array(bytes[start ..< start + size]))
            start += size
        }
        return cookies
    }

    private static func page(_ page: [UInt8]) throws(Unreadable) -> [Cookie] {
        guard try big(page, 0) == 0x100 else { throw Unreadable() }
        let count = Int(try little(page, 4))
        var cookies: [Cookie] = []
        for index in 0 ..< count {
            let offset = Int(try little(page, 8 + index * 4))
            guard offset + 4 <= page.count else { throw Unreadable() }
            let size = Int(try little(page, offset))
            guard size >= 0x38, offset + size <= page.count else { throw Unreadable() }
            cookies.append(try cookie(Array(page[offset ..< offset + size])))
        }
        return cookies
    }

    private static func cookie(_ record: [UInt8]) throws(Unreadable) -> Cookie {
        let flags = try little(record, 8)
        let expiry = Date(timeIntervalSinceReferenceDate: try double(record, 0x28))
        return Cookie(
            domain: try string(record, at: Int(try little(record, 0x10))),
            name: try string(record, at: Int(try little(record, 0x14))),
            path: try string(record, at: Int(try little(record, 0x18))),
            value: try string(record, at: Int(try little(record, 0x1C))),
            expires: expiry,
            secure: flags & 0x1 != 0,
            httpOnly: flags & 0x4 != 0,
            hostOnly: flags & 0x20 != 0,
            sameSite: flags & 0x10 != 0 ? .strict : flags & 0x8 != 0 ? .lax : nil
        )
    }

    /// The C string at `offset` of `record`, ended before the record ends.
    private static func string(_ record: [UInt8], at offset: Int) throws(Unreadable) -> String {
        guard offset >= 0x38, offset < record.count, let end = record[offset...].firstIndex(of: 0) else {
            throw Unreadable()
        }
        return String(decoding: record[offset ..< end], as: UTF8.self)
    }

    private static func big(_ bytes: [UInt8], _ at: Int) throws(Unreadable) -> UInt32 {
        UInt32(try integer(bytes, at, width: 4, bigEndian: true))
    }

    private static func little(_ bytes: [UInt8], _ at: Int) throws(Unreadable) -> UInt32 {
        UInt32(try integer(bytes, at, width: 4, bigEndian: false))
    }

    private static func double(_ bytes: [UInt8], _ at: Int) throws(Unreadable) -> Double {
        Double(bitPattern: try integer(bytes, at, width: 8, bigEndian: false))
    }

    /// `width` bytes at `at`, in the order said; refused past the end.
    private static func integer(_ bytes: [UInt8], _ at: Int, width: Int, bigEndian: Bool) throws(Unreadable) -> UInt64 {
        guard at >= 0, at + width <= bytes.count else { throw Unreadable() }
        let slice = bytes[at ..< at + width]
        let ordered = bigEndian ? Array(slice) : slice.reversed()
        return ordered.reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
    }
}
