package import Foundation

/// A blocking list in Adblock Plus syntax (EasyList, EasyPrivacy) as WebKit's content rules (roadmap 0022 W-c). What WebKit
/// cannot do (a regular expression, a rewritten response, a scriptlet, an exception for one selector) is left out and
/// counted, never approximated. The list is third-party text: it can only block or hide (white paper §9).
package enum BlockingRules {
    /// WebKit's limit for one compiled list.
    package static let webKitLimit = 150_000

    package struct Converted: Sendable, Equatable {
        package var rules: [Rule] = []
        /// Lines that are filters and were left out.
        package var skipped = 0
    }

    /// One content rule, as WebKit reads it.
    package struct Rule: Codable, Sendable, Equatable {
        package var trigger: Trigger
        package var action: Action

        package struct Trigger: Codable, Sendable, Equatable {
            package var urlFilter: String
            package var urlFilterIsCaseSensitive: Bool?
            package var resourceType: [String]?
            package var loadType: [String]?
            package var ifDomain: [String]?
            package var unlessDomain: [String]?

            private enum CodingKeys: String, CodingKey {
                case urlFilter = "url-filter"
                case urlFilterIsCaseSensitive = "url-filter-is-case-sensitive"
                case resourceType = "resource-type"
                case loadType = "load-type"
                case ifDomain = "if-domain"
                case unlessDomain = "unless-domain"
            }
        }

        package struct Action: Codable, Sendable, Equatable {
            package var type: String
            package var selector: String?
        }
    }

    /// Converts a list.
    /// - Parameters:
    ///   - text: the list as fetched.
    ///   - limit: the most rules kept; the rest are counted as left out.
    /// - Returns: element hiding first, then blocking, then the exceptions (which undo only what comes before them).
    package static func convert(_ text: String, limit: Int = webKitLimit) -> Converted {
        var hiding = Cosmetic()
        var blocks: [Rule] = []
        var exceptions: [Rule] = []
        var skipped = 0
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("!") || line.hasPrefix("[") { continue }
            if line.contains("#") && Cosmetic.isCosmetic(line) {
                if !hiding.add(line) { skipped += 1 }
                continue
            }
            guard let rule = Network.rule(line) else {
                skipped += 1
                continue
            }
            if rule.action.type == "ignore-previous-rules" { exceptions.append(rule) } else { blocks.append(rule) }
        }
        let all = hiding.rules() + blocks + exceptions
        return Converted(rules: Array(all.prefix(limit)), skipped: skipped + max(all.count - limit, 0))
    }

    /// The rules as the JSON WebKit compiles.
    package static func json(_ rules: [Rule]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return try encoder.encode(rules)
    }
}

extension StringProtocol {
    /// Only ASCII: what WebKit's rules take.
    var isASCII: Bool {
        utf8.allSatisfy { $0 < 0x80 }
    }
}
