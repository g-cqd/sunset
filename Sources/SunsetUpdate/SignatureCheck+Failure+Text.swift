public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension SignatureCheck.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .unreadable: "The downloaded app has no readable signature."
            case .refused: "The downloaded app is not signed and notarized as Sunset."
            case .notLater(let running, let staged):
                "The downloaded app (build \(staged.map(String.init) ?? "unknown")) is not newer than this one (build \(running))."
        }
    }
}
