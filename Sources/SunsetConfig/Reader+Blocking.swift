internal import AemiJSONCore

extension Reader {
    /// `web.blockingLists`: https addresses only; anything else is said and left out.
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

    /// `web.proxy`: empty, or an http or socks5 address with a host and a port.
    mutating func readProxy(_ value: JSONValue) {
        guard let address = string("web.proxy", value) else { return }
        guard !address.isEmpty else {
            configuration.web.proxy = ""
            return
        }
        let parts = address.split(separator: "://", maxSplits: 1)
        let scheme = parts.first.map { $0.lowercased() } ?? ""
        let rest = parts.count == 2 ? parts[1] : ""
        let hostAndPort = rest.split(separator: ":")
        guard ["http", "socks5", "socks"].contains(scheme), hostAndPort.count == 2, !hostAndPort[0].isEmpty,
            let port = Int(hostAndPort[1].prefix { $0 != "/" }), (1 ... 65_535).contains(port)
        else {
            issue("web.proxy", "expected http://host:port or socks5://host:port")
            return
        }
        configuration.web.proxy = address
    }
}
