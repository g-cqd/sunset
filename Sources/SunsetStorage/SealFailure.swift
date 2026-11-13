/// Why a sealed thing did not open.
public enum SealFailure: Error, Sendable, Equatable {
    /// It is not sealed at all (plain data from before sealing, or something else).
    case notSealed
    /// Sealed by a later Sunset, in a format this one does not know.
    case unknownVersion
    /// Sealed with another key: this Mac's key is not the one that sealed it (the recovery code of that key opens it).
    case otherKey
    /// Altered, cut short, or sealed as another thing: nothing of it is given.
    case damaged
}
