/// A file could not be written: the step that failed and the system's error number. The old file is as it was.
public struct StorageFailure: Error, Sendable, Equatable {
    public let step: String
    public let code: Int32
}
