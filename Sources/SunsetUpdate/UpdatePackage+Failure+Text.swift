public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension UpdatePackage.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .notAPackage, .malformed: "The update package could not be read."
            case .outside(let path): "The update would write outside the app (\(path))."
        }
    }
}
