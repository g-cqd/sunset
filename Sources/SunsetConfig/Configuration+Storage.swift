extension Configuration {
    /// `storage.*`.
    public struct Storage: Sendable, Equatable {
        /// What becomes of a plain file of before, once what it held is in the sealed store.
        public enum ImportedFiles: String, Sendable, Equatable, CaseIterable {
            /// The Mac's Trash: readable until it is emptied, nothing destroyed.
            case trash
            /// Removed: no plain copy is left.
            case delete
        }

        public var importedFiles = ImportedFiles.trash
        /// Seal saved terminal screen & scrollback snapshots on disk with the Keychain/Secure Enclave storage key
        /// (roadmap 0024 S-4 / t215). On by default so scrollback stays protected at rest.
        public var encryptTerminalHistory = true

        public init() {}
    }
}
