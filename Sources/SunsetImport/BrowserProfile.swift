/// A profile of another browser's: the folder it lives in, under the browser's own, and the name the person gave it.
public struct BrowserProfile: Sendable, Equatable {
    public var folder: String
    public var name: String

    public init(folder: String, name: String) {
        self.folder = folder
        self.name = name
    }
}
