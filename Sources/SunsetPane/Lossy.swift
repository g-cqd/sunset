/// A part of a saved file that fails to read is nil instead of failing the whole file (a window, a Space, a profile written
/// by a newer build, or damaged).
struct Lossy<Value: Codable>: Codable {
    let value: Value?

    init(_ value: Value) {
        self.value = value
    }

    init(from decoder: any Decoder) throws {
        value = try? Value(from: decoder)
    }

    func encode(to encoder: any Encoder) throws {
        try value?.encode(to: encoder)
    }
}
