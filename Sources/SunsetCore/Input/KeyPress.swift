public struct KeyPress: Sendable, Equatable {
    public var code: KeyCode
    public var modifiers: InputModifiers
    /// The text the key produced with the modifiers applied (shift, dead keys and the keyboard layout included), for character keys; empty or nil for the others.
    public var text: String?

    public init(_ code: KeyCode, modifiers: InputModifiers = [], text: String? = nil) {
        self.code = code
        self.modifiers = modifiers
        self.text = text
    }
}
