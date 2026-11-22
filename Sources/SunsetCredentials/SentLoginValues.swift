public import Foundation

/// A password sent from a page, with its username and the origin of its frame.
public struct SentLoginValues: Equatable, Sendable {
    public var origin: URL
    public var username: String
    public var password: String

    public init(origin: URL, username: String, password: String) {
        self.origin = origin
        self.username = username
        self.password = password
    }
}
