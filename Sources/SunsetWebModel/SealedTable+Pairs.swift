import Foundation
package import SunsetStorage

/// A table of one value for each key, each record `<key>\n<value>` (roadmap 0086 E: the site rules and the sites' zoom
/// wrote and read their records the same way).
extension SealedTable {
    /// Every record's key and value; a record that is not one is skipped.
    package func pairs() -> [(key: String, value: String)] {
        all().rows
            .compactMap { row in
                guard let text = String(data: row.payload, encoding: .utf8) else { return nil }
                let parts = text.split(separator: "\n", maxSplits: 1)
                return parts.count == 2 ? (String(parts[0]), String(parts[1])) : nil
            }
    }

    /// Keeps `value` for `key`.
    package func put(_ key: String, value: String) {
        put(key, payload: Data("\(key)\n\(value)".utf8))
    }
}
