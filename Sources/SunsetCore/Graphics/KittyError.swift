/// What a kitty graphics command is answered when it is not done, as kitty answers (`CODE:message`), short enough for a
/// reply.
enum KittyError: Error, Equatable {
    /// Fewer bytes than its size asks.
    case noData
    /// A file, a temporary file or shared memory (ADR-0117: never opened on a program's word).
    case forbidden
    /// A format, a compression, a size or an action not supported.
    case invalid
    /// No image of that id.
    case noEntry
    /// Larger than the quota.
    case noSpace

    var message: StaticString {
        switch self {
            case .noData: "ENODATA:Insufficient image data"
            case .forbidden: "EPERM:Only data in the escape is read"
            case .invalid: "EINVAL:Not supported"
            case .noEntry: "ENOENT:No such image"
            case .noSpace: "ENOSPC:Larger than the quota"
        }
    }
}
