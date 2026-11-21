public import Foundation

/// An extension installed in another browser (roadmap 0111 F): offered to the person through its store page, where
/// Sunset installs it as from any store page (roadmap 0109 E), granted by the person; never installed silently.
public struct BrowserExtension: Sendable, Equatable {
    public var id: String
    public var name: String
    public var store: URL?
    public var isEnabled: Bool

    public init(id: String, name: String, store: URL?, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.store = store
        self.isEnabled = isEnabled
    }
}
