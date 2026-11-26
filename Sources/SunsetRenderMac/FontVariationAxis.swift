internal import Foundation

/// A variable font axis coordinate (`wght=550`, `opsz=14`, `slnt=-10` — T-7 / t182).
/// `tag` must be a 4-character ASCII OpenType axis tag; `value` is the axis value in design-space units.
public struct FontVariationAxis: Sendable, Equatable, Hashable {
    public var tag: String
    public var value: Double

    public init(_ tag: String, _ value: Double) {
        self.tag = tag
        self.value = value
    }

    /// Four-byte big-endian OpenType tag (`FourCharCode`), or nil if `tag` is not 4 ASCII characters.
    package var fourCharCode: UInt32? {
        let bytes = Array(tag.utf8)
        guard bytes.count == 4, bytes.allSatisfy({ $0 >= 0x20 && $0 <= 0x7E }) else { return nil }
        return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
    }

    /// Parses comma-separated `tag=value` entries (e.g. `"wght=550, wdth=100"`), skipping invalid entries safely.
    public static func parseList(_ text: String) -> [Self] {
        text.split(separator: ",")
            .compactMap { entry in
                let parts = entry.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard parts.count == 2, let value = Double(parts[1]), value.isFinite else { return nil }
                let axis = Self(parts[0], value)
                return axis.fourCharCode != nil ? axis : nil
            }
    }
}
