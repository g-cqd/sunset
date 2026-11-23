public import Foundation

/// What the update centre says of this refusal: a sentence, not a type's name.
extension ReleaseIndex.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .untrustedSignature: "The release is not signed by Sunset\u{2019}s release key."
            case .malformed: "The release\u{2019}s index could not be read."
        }
    }
}
