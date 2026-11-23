public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension UpdateInstaller.Failure: LocalizedError {
    public var errorDescription: String? {
        "The downloaded archive does not hold one app."
    }
}
