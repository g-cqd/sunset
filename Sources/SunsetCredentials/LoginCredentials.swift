import Foundation

/// What is filled into a page's sign-in form.
public struct LoginCredentials: Equatable, Sendable {
    public var username: String
    public var password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}
