/// The kinds of characters a generated password is drawn from.
public enum CharacterClass: CaseIterable, Sendable {
    case lower, upper, digit, symbol

    public var characters: String {
        switch self {
            case .lower: "abcdefghijklmnopqrstuvwxyz"
            case .upper: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            case .digit: "0123456789"
            case .symbol: "!#$%&()*+,-./:;<=>?@[]^_{|}~"
        }
    }

    /// Characters read one for another (I, l and 1; O, 0 and o), left out on request.
    static let lookalikes: Set<Character> = ["I", "l", "1", "O", "0", "o"]
}
