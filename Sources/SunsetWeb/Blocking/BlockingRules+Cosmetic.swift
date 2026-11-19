import Foundation

extension BlockingRules {
    /// Element hiding: `##selector` everywhere, `site.com##selector` on its sites. The extended syntaxes (`#?#`, `#$#`) and
    /// the exceptions for one selector (`#@#`: WebKit cannot show again what a rule hid) are left out.
    struct Cosmetic {
        /// Selectors hidden everywhere, grouped so that WebKit has fewer rules to compile.
        private var everywhere: [String] = []
        private var bySite: [Rule] = []
        private static let groupSize = 100
        /// Pseudo-classes of the lists' own, which a browser's CSS does not know.
        private static let foreign = [
            ":-abp-", ":has-text(", ":xpath(", ":style(", ":matches-css", ":upward(", ":remove(",
            // A scriptlet: never run, nor taken for a selector.
            "+js("
        ]

        static func isCosmetic(_ line: String) -> Bool {
            line.contains("##") || line.contains("#@#") || line.contains("#?#") || line.contains("#$#")
        }

        /// Takes a line; false when it is one left out.
        mutating func add(_ line: String) -> Bool {
            guard let marker = line.range(of: "##"), !line.contains("#@#"), !line.contains("#?#"), !line.contains("#$#")
            else { return false }
            let selector = String(line[marker.upperBound...])
            // `##^…` is an HTML filter, not a selector.
            guard !selector.isEmpty, !selector.hasPrefix("^"), selector.isASCII,
                !Self.foreign.contains(where: selector.contains)
            else {
                return false
            }
            let sites = line[..<marker.lowerBound].split(separator: ",").map(String.init)
            if sites.isEmpty {
                everywhere.append(selector)
                return true
            }
            // Every site a host name, or the line is left out: dropping one of `~a.com,b.*` would hide more than it says.
            guard BlockingRules.areSites(sites) else { return false }
            let on = sites.filter { !$0.hasPrefix("~") }.map { "*" + $0 }
            guard !on.isEmpty else { return false }
            bySite.append(
                Rule(
                    trigger: Rule.Trigger(urlFilter: ".*", ifDomain: on),
                    action: Rule.Action(type: "css-display-none", selector: selector)
                )
            )
            return true
        }

        func rules() -> [Rule] {
            let groups = stride(from: 0, to: everywhere.count, by: Self.groupSize)
                .map {
                    everywhere[$0 ..< min($0 + Self.groupSize, everywhere.count)].joined(separator: ", ")
                }
            let general = groups.map {
                Rule(
                    trigger: Rule.Trigger(urlFilter: ".*"),
                    action: Rule.Action(type: "css-display-none", selector: $0)
                )
            }
            return general + bySite
        }
    }
}
