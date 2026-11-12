internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// `web.engines`: an array of `{ "name", "keyword", "search", "suggest"? }`; the addresses must hold `%s`. An entry that is not one is reported
    /// and left out.
    mutating func readEngines(_ value: JSONValue) {
        guard case .array(let entries) = value else {
            issue("web.engines", "expected an array of engines")
            return
        }
        configuration.web.engines = entries.enumerated()
            .compactMap { index, entry in engine(entry, path: "web.engines[\(index)]") }
    }

    private mutating func engine(_ entry: JSONValue, path: String) -> Configuration.Web.Engine? {
        guard case .object(let object) = entry,
            case .string(let name)? = object["name"], case .string(let keyword)? = object["keyword"],
            case .string(let search)? = object["search"], search.contains("%s"), !name.isEmpty
        else {
            issue(path, "expected { \"name\", \"keyword\", \"search\" with %s, \"suggest\" }")
            return nil
        }
        var suggest: String?
        if case .string(let text)? = object["suggest"] {
            if text.contains("%s") { suggest = text } else { issue(path + ".suggest", "expected an address with %s") }
        }
        return Configuration.Web.Engine(name: name, keyword: keyword, search: search, suggest: suggest)
    }
}
