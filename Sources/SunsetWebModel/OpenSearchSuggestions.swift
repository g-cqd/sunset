package import Foundation

/// The suggestions of an engine's answer in the OpenSearch JSON format: `[query, [suggestion, …], …]`; nothing for anything else.
package enum OpenSearchSuggestions {
    package static func parse(_ data: Data, limit: Int = 8) -> [String] {
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [Any], array.count > 1,
            let list = array[1] as? [Any]
        else { return [] }
        return Array(list.compactMap { $0 as? String }.prefix(limit))
    }
}
