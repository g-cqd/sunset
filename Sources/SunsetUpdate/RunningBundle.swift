public import Foundation

/// The app being updated: where it is, its build, which flavour, for which architecture.
public struct RunningBundle: Sendable {
    public let bundle: URL
    public let build: Int
    public let flavour: Flavour
    public let architecture: String

    public init(bundle: URL, build: Int, flavour: Flavour, architecture: String) {
        self.bundle = bundle
        self.build = build
        self.flavour = flavour
        self.architecture = architecture
    }
}
