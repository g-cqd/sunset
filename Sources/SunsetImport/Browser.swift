/// A browser Sunset can import from, and the folder it keeps its data in, under the person's home.
public struct Browser: Sendable, Equatable, Identifiable {
    public var id: String {
        name
    }
    public let name: String
    public let kind: BrowserKind
    /// Under the home folder: `Library/Application Support/Google/Chrome`.
    public let folder: String

    public init(name: String, kind: BrowserKind, folder: String) {
        self.name = name
        self.kind = kind
        self.folder = folder
    }
}
