/// An option of Settings that is one of a few named values: each as the file writes it, with what the menu calls it.
public struct SettingsChoice: Sendable {
    public struct Item: Sendable, Equatable {
        public let value: String
        public let label: String
    }

    public let items: [Item]
    public let get: @Sendable (Configuration) -> String
    public let set: @Sendable (inout Configuration, String) -> Void

    /// - Parameters:
    ///   - path: where the value is in the configuration.
    ///   - items: the values in the menu's order, each with its name there.
    public init<Value: RawRepresentable & Sendable>(
        _ path: any WritableKeyPath<Configuration, Value> & Sendable,
        _ items: [(Value, String)]
    ) where Value.RawValue == String {
        self.items = items.map { Item(value: $0.0.rawValue, label: $0.1) }
        get = {
            $0[keyPath: path].rawValue
        }
        set = { configuration, raw in
            if let value = Value(rawValue: raw) { configuration[keyPath: path] = value }
        }
    }
}
