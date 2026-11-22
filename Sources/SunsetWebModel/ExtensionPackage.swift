package import Foundation

/// What WebKit loads from what the person picks: `.xpi` and `.zip` are zips, taken as they are; a Chrome Web Store `.crx`
/// (CRX3) is a zip behind a header ("Cr24", the version 3, the header's length, the header, a protocol buffer of keys and
/// signatures), taken off. CRX2 (retired by Chrome in 2019) and anything else are refused.
package enum ExtensionPackage {
    package struct Refused: Error, Equatable, Sendable {
        package let reason: String
    }

    private static let zipMagic = Data([0x50, 0x4B, 0x03, 0x04])
    private static let crxMagic = Data("Cr24".utf8)

    package static func zip(from data: Data) throws(Refused) -> Data {
        if data.starts(with: zipMagic) { return data }
        guard data.starts(with: crxMagic) else { throw Refused(reason: "not a zip, an .xpi or a .crx") }
        guard data.count >= 12 else { throw Refused(reason: "a .crx too short for its header") }
        let version = uint32(data, at: 4)
        guard version == 3 else { throw Refused(reason: "a .crx of version \(version); only version 3 is read") }
        let start = 12 + Int(uint32(data, at: 8))
        guard start <= data.count, data.dropFirst(start).starts(with: zipMagic) else {
            throw Refused(reason: "a .crx whose archive is not where its header says")
        }
        return Data(data.dropFirst(start))
    }

    /// An extension's package a page offers: by its type (Chrome's, Firefox's), or its name ending `.crx` or `.xpi`
    /// (stores serve them as plain bytes too). A `.zip` is a download like any other.
    package static func isPackage(mime: String?, path: String) -> Bool {
        let types: Set = ["application/x-chrome-extension", "application/x-xpinstall"]
        if let mime, types.contains(mime.lowercased()) { return true }
        let name = path.lowercased()
        return name.hasSuffix(".crx") || name.hasSuffix(".xpi")
    }

    /// A little-endian 32-bit number at `offset`, counted from the start of `data`.
    private static func uint32(_ data: Data, at offset: Int) -> UInt32 {
        let start = data.startIndex + offset
        return data[start ..< start + 4].reversed().reduce(0) { $0 << 8 | UInt32($1) }
    }
}
