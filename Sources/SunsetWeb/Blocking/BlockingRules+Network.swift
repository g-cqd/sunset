import Foundation

extension BlockingRules {
    /// A filter on what a page loads: `||host^`, `|https://…`, `/path/*`, with `$options`; `@@` lets through.
    enum Network {
        /// WebKit's resource types for the list's.
        private static let types: [String: String] = [
            "script": "script", "image": "image", "stylesheet": "style-sheet", "font": "font", "media": "media",
            "xmlhttprequest": "raw", "xhr": "raw", "websocket": "raw", "subdocument": "document", "popup": "popup",
            "ping": "ping", "other": "other", "object": "other"
        ]
        private static let allTypes = Array(Set(types.values)).sorted()

        static func rule(_ line: String) -> Rule? {
            var body = Substring(line)
            let isException = body.hasPrefix("@@")
            if isException { body = body.dropFirst(2) }
            // A regular expression: WebKit's subset is narrower than the list's.
            if body.hasPrefix("/"), body.hasSuffix("/") || body.contains("/$") { return nil }
            var options: [Substring] = []
            if let dollar = body.lastIndex(of: "$") {
                options = body[body.index(after: dollar)...].split(separator: ",")
                body = body[..<dollar]
            }
            guard let filter = urlFilter(body) else { return nil }
            var trigger = Rule.Trigger(urlFilter: filter)
            var wholePage = false
            for option in options {
                guard apply(option, to: &trigger, wholePage: &wholePage) else { return nil }
            }
            if wholePage {
                // `@@||site^$document`: nothing is blocked on the site's pages.
                guard isException, body.hasPrefix("||"), let host = host(of: body) else { return nil }
                trigger = Rule.Trigger(urlFilter: ".*", ifDomain: ["*" + host])
            }
            return Rule(trigger: trigger, action: Rule.Action(type: isException ? "ignore-previous-rules" : "block"))
        }

        /// One option; false for one WebKit cannot do (the rule is then left out).
        private static func apply(_ option: Substring, to trigger: inout Rule.Trigger, wholePage: inout Bool) -> Bool {
            let negated = option.hasPrefix("~")
            let name = String(negated ? option.dropFirst() : option).lowercased()
            switch name {
                case "third-party", "3p": trigger.loadType = [negated ? "first-party" : "third-party"]
                case "first-party", "1p": trigger.loadType = [negated ? "third-party" : "first-party"]
                case "match-case": trigger.urlFilterIsCaseSensitive = true
                case "important": break
                case "document": wholePage = !negated
                case _ where name.hasPrefix("domain="): return domains(String(name.dropFirst(7)), into: &trigger)
                default:
                    guard let type = types[name] else { return false }
                    var current = trigger.resourceType ?? (negated ? allTypes : [])
                    if negated {
                        current.removeAll { $0 == type }
                    } else if !current.contains(type) {
                        current.append(type)
                    }
                    trigger.resourceType = current
            }
            return true
        }

        /// `a.com|~b.a.com`: WebKit takes either sites to apply on or sites to leave alone, not both: the first kind given wins.
        private static func domains(_ list: String, into trigger: inout Rule.Trigger) -> Bool {
            let names = list.split(separator: "|").map(String.init)
            guard BlockingRules.areSites(names) else { return false }
            let on = names.filter { !$0.hasPrefix("~") }.map { "*" + $0 }
            let off = names.filter { $0.hasPrefix("~") }.map { "*" + $0.dropFirst() }
            guard (on + off).allSatisfy({ $0.isASCII }) else { return false }
            if !on.isEmpty { trigger.ifDomain = on } else if !off.isEmpty { trigger.unlessDomain = off }
            return true
        }

        private static func host(of body: Substring) -> String? {
            let host = body.dropFirst(2).prefix { $0 != "^" && $0 != "/" && $0 != "*" }
            return host.isEmpty ? nil : String(host).lowercased()
        }

        /// The list's pattern as WebKit's regular expression: `||` the host and its subdomains, `|` an end, `*` anything,
        /// `^` a separator (a URL always has one after its host). Nil for anything not ASCII.
        static func urlFilter(_ pattern: Substring) -> String? {
            guard pattern.isASCII else { return nil }
            var body = pattern
            var regex = ""
            if body.hasPrefix("||") {
                regex = #"^[^:]+://+([^:/]+\.)?"#
                body = body.dropFirst(2)
            } else if body.hasPrefix("|") {
                regex = "^"
                body = body.dropFirst()
            }
            let anchoredEnd = body.hasSuffix("|")
            if anchoredEnd { body = body.dropLast() }
            for character in body {
                switch character {
                    case "*": regex += ".*"
                    case "^": regex += "[^a-zA-Z0-9_.%-]"
                    case ".", "+", "?", "(", ")", "[", "]", "{", "}", "\\", "$", "|": regex += "\\" + String(character)
                    default: regex.append(character)
                }
            }
            if anchoredEnd { regex += "$" }
            return regex.isEmpty ? ".*" : regex
        }
    }
}
