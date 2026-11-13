import Foundation

/// Something Sunset keeps did not read (R12: never dropped silently): what it was, where, and where it was moved aside.
public struct StorageProblem: Identifiable, Sendable, Equatable {
    public var id: String { path + (movedTo ?? "") }
    /// What it is, as said to the person: "The saved session".
    public let what: String
    public let path: String
    /// Where the unread file is now; nil when it could not be moved (it is then still in place).
    public let movedTo: String?

    public init(what: String, path: String, movedTo: String?) {
        self.what = what
        self.path = path
        self.movedTo = movedTo
    }

    public var sentence: String {
        guard let movedTo else { return "\(what) could not be read, and could not be moved aside." }
        return "\(what) could not be read. It was moved aside as \((movedTo as NSString).lastPathComponent)."
    }
}
