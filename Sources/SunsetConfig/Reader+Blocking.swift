internal import AemiJSONCore

extension Reader {
    /// `web.blockingLists`: https addresses only; anything else is said and left out (roadmap 0022 W-c).
    mutating func readBlockingLists(_ value: JSONValue) {
        guard case .array(let entries) = value else {
            issue("web.blockingLists", "expected an array of https addresses")
            return
        }
        var lists: [String] = []
        for (index, entry) in entries.enumerated() {
            guard case .string(let address) = entry, address.lowercased().hasPrefix("https://"), address.count > 8
            else {
                issue("web.blockingLists[\(index)]", "expected an https address")
                continue
            }
            lists.append(address)
        }
        configuration.web.blockingLists = lists
    }
}
