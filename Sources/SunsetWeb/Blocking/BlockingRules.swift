package import Foundation

/// A blocking list in Adblock Plus syntax (EasyList, EasyPrivacy) as WebKit's content rules (roadmap 0022 W-c). What WebKit
/// cannot do (a regular expression, a rewritten response, a scriptlet, an exception for one selector) is left out and
/// counted, never approximated. The list is third-party text: it can only block or hide (white paper §9).
package enum BlockingRules {
    /// WebKit's limit for one compiled list.
    package static let webKitLimit = 150_000
    /// The most compiled lists one list may fill (OISD's big list needs two): a list stays bounded (white paper §9).
    package static let maxParts = 4

    package struct Converted: Sendable, Equatable {
        package var rules: [Rule] = []
        /// Lines that are filters and were left out.
        package var skipped = 0
        /// How many of `rules`, at their end, are exceptions: each compiled part carries them all, since WebKit's
        /// `ignore-previous-rules` undoes only what comes before it in its own list.
        package var exceptions = 0
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
    ///   - limit: the most rules in one compiled list (WebKit's).
    ///   - parts: the most compiled lists the rules may fill (`Converted.parts`); past them, the rest are left out.
    /// - Returns: element hiding first, then blocking, then the exceptions (which undo only what comes before them).
    package static func convert(_ text: String, limit: Int = webKitLimit, parts: Int = maxParts) -> Converted {
        var hiding = Cosmetic()
        var blocks: [Rule] = []
        var exceptions: [Rule] = []
        var skipped = 0
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("!") || line.hasPrefix("[") || isComment(line) { continue }
            if let hosts = Hosts.hosts(line) {
                blocks += hosts.compactMap(Hosts.rule)
                continue
            }
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
        let kept = Array(exceptions.prefix(limit))
        let body = hiding.rules() + blocks
        let room = max(limit - kept.count, 0) * max(parts, 1)
        let dropped = max(body.count - room, 0) + (exceptions.count - kept.count)
        return Converted(rules: Array(body.prefix(room)) + kept, skipped: skipped + dropped, exceptions: kept.count)
    }

    /// The rules as the JSON WebKit compiles.
    package static func json(_ rules: [Rule]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return try encoder.encode(rules)
    }
}

extension BlockingRules.Converted {
    /// The rules in compiled lists of at most `limit` rules each: the rules in order, every exception at the end of each.
    package func parts(limit: Int = BlockingRules.webKitLimit) -> [[BlockingRules.Rule]] {
        let shared = Array(rules.suffix(exceptions))
        let body = rules.dropLast(exceptions)
        let room = max(limit - shared.count, 1)
        if body.isEmpty { return shared.isEmpty ? [] : [shared] }
        return stride(from: body.startIndex, to: body.endIndex, by: room)
            .map {
                Array(body[$0 ..< min($0 + room, body.endIndex)]) + shared
            }
    }
}

extension StringProtocol {
    /// Only ASCII: what WebKit's rules take.
    var isASCII: Bool {
        utf8.allSatisfy { $0 < 0x80 }
    }
}
