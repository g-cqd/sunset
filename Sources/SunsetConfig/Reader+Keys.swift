internal import AemiJSONCore
internal import OrderedCollections

extension Reader {
    /// `keys`: an object of commands' names and their keys, each a string. Whether a name is a command and a key one the
    /// menus can show is the app's to say, which knows its commands.
    mutating func readKeys(_ value: JSONValue) {
        guard case .object(let object) = value else {
            issue("keys", "expected an object of commands and their keys")
            return
        }
        var keys: [String: String] = [:]
        for (name, entry) in object {
            if let key = string("keys.\(name)", entry) { keys[name] = key }
        }
        configuration.keys = keys
    }
}
