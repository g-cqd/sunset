/// How an option of Settings reads and writes its value in the configuration.
public struct SettingsValue<Value: Sendable>: Sendable {
    public let get: @Sendable (Configuration) -> Value
    public let set: @Sendable (inout Configuration, Value) -> Void

    public init(
        get: @escaping @Sendable (Configuration) -> Value,
        set: @escaping @Sendable (inout Configuration, Value) -> Void
    ) {
        self.get = get
        self.set = set
    }

    public init(_ path: any WritableKeyPath<Configuration, Value> & Sendable) {
        get = {
            $0[keyPath: path]
        }
        set = {
            $0[keyPath: path] = $1
        }
    }
}
