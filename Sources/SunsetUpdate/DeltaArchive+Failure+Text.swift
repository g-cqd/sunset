public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension DeltaArchive.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .notAnArchive, .malformed: "The update archive could not be read."
            case .hashMismatch: "The downloaded update does not match what the release describes."
            case .duplicatePath(let path), .outside(let path), .unsafeLink(let path):
                "The update would write outside the app (\(path))."
            case .missingSource(let source): "No update is published for this build (\(source))."
            case .sizeLimitExceeded: "The update is larger than an update may be."
        }
    }
}
