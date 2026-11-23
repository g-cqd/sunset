public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension UpdateStaging.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .notTheManifest: "The rebuilt app does not match what the release describes."
            case .missing(let path): "This copy of Sunset is missing a file the update needs (\(path))."
        }
    }
}
