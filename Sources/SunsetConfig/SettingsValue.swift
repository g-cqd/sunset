/// How an option of Settings reads and writes its value in the configuration.
public struct SettingsValue<Value: Sendable>: Sendable {
    public let get: @Sendable (Configuration) -> Value
    public let set: @Sendable (inout Configuration, Value) -> Void
    /// Made from a key path: what the control shows is what the file holds, so the file is read and written through it.
    /// A value made of its own getter and setter is not.
    public let isDirect: Bool

    public init(
        get: @escaping @Sendable (Configuration) -> Value,
        set: @escaping @Sendable (inout Configuration, Value) -> Void
    ) {
        self.get = get
        self.set = set
        isDirect = false
    }

    public init(_ path: any WritableKeyPath<Configuration, Value> & Sendable) {
        get = {
            $0[keyPath: path]
        }
        set = {
            $0[keyPath: path] = $1
        }
        isDirect = true
    }
}
