extension Configuration {
    /// `storage.*` (R12).
    public struct Storage: Sendable, Equatable {
        /// What becomes of a plain file of before, once what it held is in the sealed store.
        public enum ImportedFiles: String, Sendable, Equatable, CaseIterable {
            /// The Mac's Trash: readable until it is emptied, nothing destroyed.
            case trash
            /// Removed: no plain copy is left.
            case delete
        }

        public var importedFiles = ImportedFiles.trash

        public init() {}
    }
}
