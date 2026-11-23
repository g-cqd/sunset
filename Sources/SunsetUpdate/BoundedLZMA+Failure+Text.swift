public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension BoundedLZMA.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .malformed: "Part of the update could not be decompressed."
            case .outputLimitExceeded: "Part of the update expands beyond its declared size."
        }
    }
}
