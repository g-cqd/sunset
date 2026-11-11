import Foundation

/// The icon a user gives a tab or a folder of the sidebar, over the one its content has (`n40`, `n41`): an SF Symbol by name, or an emoji.
public enum PaneIcon: Sendable, Equatable {
    case symbol(String)
    case emoji(String)

    /// What a person typed for an icon: a symbol's name when it is made of what those names are made of (ASCII letters, digits and dots), otherwise its
    /// first character, as it is (an emoji); nothing when it is blank. Whether a symbol of that name exists is for the view to say.
    public init?(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return nil }
        let isName = trimmed.unicodeScalars.allSatisfy { scalar in
            scalar.isASCII && (scalar.properties.isAlphabetic || scalar.properties.numericType != nil || scalar == ".")
        }
        self = isName ? .symbol(trimmed) : .emoji(String(first))
    }

    /// The icon as it is typed.
    public var text: String {
        switch self {
            case .symbol(let name): name
            case .emoji(let emoji): emoji
        }
    }
}
