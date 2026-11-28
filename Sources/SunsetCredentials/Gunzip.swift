import Foundation

/// A gzip member's data, inflated (RFC 1952: its header, a DEFLATE stream, its trailer): a KeePass database's payload.
/// The inflated size is bounded: a small file inflating past it is refused, not followed.
enum Gunzip {
    /// The most bytes a database's XML may inflate to.
    static let largest = 512 << 20

    static func inflate(_ data: [UInt8]) throws(KeePassFile.Failure) -> [UInt8] {
        guard data.count >= 18, data[0] == 0x1F, data[1] == 0x8B, data[2] == 8 else { throw .damaged }
        let flags = data[3]
        var start = 10
        if flags & 4 != 0 {
            guard start + 2 <= data.count else { throw .damaged }
            start += 2 + Int(data[start]) | Int(data[start + 1]) << 8
        }
        for flag in [UInt8(8), 16] where flags & flag != 0 {
            guard let end = data[min(start, data.count)...].firstIndex(of: 0) else { throw .damaged }
            start = end + 1
        }
        if flags & 2 != 0 { start += 2 }
        guard start < data.count - 8 else { throw .damaged }
        return try Inflate.raw(Array(data[start ..< data.count - 8]), largest: largest)
    }
}
