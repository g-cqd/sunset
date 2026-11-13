/// Why there is no key: the place it is kept cannot be used; a recovery code does not read; or a different key is already there.
public enum StorageKeyFailure: Error, Sendable, Equatable {
    case vault
    case badCode
    case keyExists
}
