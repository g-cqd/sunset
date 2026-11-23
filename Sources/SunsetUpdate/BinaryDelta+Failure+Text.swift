public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension BinaryDelta.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .notADelta, .malformed: "Part of the update could not be read."
            case .otherOldFile: "This copy of Sunset is not the one the update was made from."
            case .wrongResult: "The update did not rebuild the expected file."
        }
    }
}
