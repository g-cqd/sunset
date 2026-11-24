extension LoginImport.SkipReason {
    /// The order the reasons are told in.
    static var inReportOrder: [Self] {
        [.notALogin, .archived, .deleted, .unknownKind, .empty]
    }

    /// What a count of rows left out for this reason is said to be.
    var words: String {
        switch self {
            case .notALogin: "notes or cards"
            case .archived: "archived"
            case .deleted: "in the trash"
            case .unknownKind: "of a kind Sunset does not know"
            case .empty: "empty"
        }
    }
}
