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
        let archive = Data(data.dropFirst(start))
        // Its signature checked before anything of it is read (CRIT-03).
        try CRX3Signature.verify(header: Data(data[data.startIndex + 12 ..< data.startIndex + start]), archive: archive)
        return archive
    }

    /// An extension's package a page offers: by its type (Chrome's CRX3) or its name ending `.crx` (stores serve them as
    /// plain bytes too). Unsigned `.zip` and `.xpi` links are left as regular downloads (N-S4: Firefox `.xpi` installs
    /// come from Firefox Add-ons' own API/host or explicit local file selection, never arbitrary page links).
    package static func isPackage(mime: String?, path: String) -> Bool {
        if let mime, mime.lowercased() == "application/x-chrome-extension" { return true }
        return path.lowercased().hasSuffix(".crx")
    }

    /// Whether a response looks like a Firefox `.xpi` package (only acted on when fetched from a trusted Mozilla host).
    package static func isFirefoxPackage(mime: String?, path: String) -> Bool {
        if let mime, mime.lowercased() == "application/x-xpinstall" { return true }
        return path.lowercased().hasSuffix(".xpi")
    }

    /// Whether a page-offered extension download URL is allowed to bypass Chrome's CRX3 signature check: only Mozilla's
    /// official Add-ons download host over HTTPS (`addons.mozilla.org`). Any other `.xpi` or `.zip` URL is refused.
    package static func isTrustedFirefoxDownload(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host()?.lowercased() else { return false }
        return host == "addons.mozilla.org"
    }

    /// A little-endian 32-bit number at `offset`, counted from the start of `data`.
    private static func uint32(_ data: Data, at offset: Int) -> UInt32 {
        let start = data.startIndex + offset
        return data[start ..< start + 4].reversed().reduce(0) { $0 << 8 | UInt32($1) }
    }
}
