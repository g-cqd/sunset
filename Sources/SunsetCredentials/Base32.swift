public import Foundation
import SunsetStorage

/// Base32 (RFC 4648), as one-time code secrets are written: decoding accepts lowercase, spaces, dashes and missing
/// padding, as people and apps type them; encoding writes the RFC's form, padded.
public enum Base32 {
    public struct Invalid: Error, Equatable {}

    private static let text = FiveBitText("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    public static func decode(_ typed: String) throws(Invalid) -> Data {
        let symbols = typed.uppercased().filter { !" -=".contains($0) }
        guard let read = text.bytes(symbols) else { throw Invalid() }
        return Data(read.bytes)
    }

    public static func encode(_ data: Data) -> String {
        var symbols = text.symbols(data)
        while symbols.count % 8 != 0 { symbols.append("=") }
        return String(symbols)
    }
}
