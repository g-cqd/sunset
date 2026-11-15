import Foundation

/// Something Sunset keeps could not be used (R12: never dropped silently): what it was, where, and what was done.
public struct StorageProblem: Identifiable, Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        /// It did not read: moved aside under a dated name (`movedTo`), and a new one is used.
        case damaged
        /// Sealed with a key this Mac does not have: left as it is, and nothing is saved over it.
        case locked
        /// The key itself could not be had (the Keychain refused): nothing is saved in this run.
        case noKey
        /// It was to be deleted and could not be: it is kept as it was.
        case notRemoved
    }

    public var id: String { path + (movedTo ?? "") + "\(kind)" }
    /// What it is, as said to the person: "The saved session".
    public let what: String
    public let path: String
    /// Where the unread file is now; nil when it was left in place.
    public let movedTo: String?
    public let kind: Kind

    public init(what: String, path: String, movedTo: String?, kind: Kind = .damaged) {
        self.what = what
        self.path = path
        self.movedTo = movedTo
        self.kind = kind
    }

    public var sentence: String {
        switch kind {
            case .locked:
                return
                    "\(what) is sealed with a key this Mac does not have. It is left as it is, and nothing is saved over it."
            case .noKey:
                return "The key that seals what Sunset keeps could not be read. \(what) is not saved in this run."
            case .notRemoved:
                return "\(what) could not be deleted. It is kept as it was."
            case .damaged:
                guard let movedTo else { return "\(what) could not be read, and could not be moved aside." }
                return "\(what) could not be read. It was moved aside as \((movedTo as NSString).lastPathComponent)."
        }
    }
}
