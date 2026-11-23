public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension BundleSwap.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .refused(let code): "Sunset could not replace itself (error \(code))."
        }
    }
}
