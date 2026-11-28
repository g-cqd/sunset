import CryptoKit
import Foundation

/// A KeePass XML key file's key: version 1.0 has it as Base64 in `<Data>`, version 2.0 as hex (spaces allowed) with the
/// first four bytes of its SHA-256 as `Hash`, checked.
enum KeePassKeyFile {
    static func key(_ text: String) -> [UInt8]? {
        guard let open = text.range(of: "<Data"),
            let close = text.range(of: "</Data>", range: open.upperBound ..< text.endIndex),
            let tagEnd = text.range(of: ">", range: open.upperBound ..< close.lowerBound)
        else { return nil }
        let attributes = String(text[open.upperBound ..< tagEnd.lowerBound])
        let content = text[tagEnd.upperBound ..< close.lowerBound].filter { !$0.isWhitespace }
        if text.contains("<Version>2.0</Version>") {
            let key = KeePassHeader.hex(String(content))
            guard key.count == 32 else { return nil }
            if let hash = attributes.split(separator: "\"").dropFirst().first, !hash.isEmpty {
                let wanted = KeePassHeader.hex(String(hash))
                guard Array(SHA256.hash(data: key).prefix(4)) == wanted else { return nil }
            }
            return key
        }
        return Data(base64Encoded: String(content)).map { [UInt8]($0) }
    }
}
