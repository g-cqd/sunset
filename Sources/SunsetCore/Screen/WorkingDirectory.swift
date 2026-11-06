/// The directory a shell says it is in (OSC 7, `file://host/path`): the host name (empty for the local machine) and the path, decoded.
public struct WorkingDirectory: Sendable, Equatable {
    public var host: String
    public var path: String

    public init(host: String, path: String) {
        self.host = host
        self.path = path
    }
}
