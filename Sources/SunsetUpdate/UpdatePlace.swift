/// Whether the running app may update itself where it is (roadmap 0122 D, ADR-0122).
public enum UpdatePlace {
    public enum Refusal: Equatable, Sendable {
        /// Not signed by a team (a development build).
        case unsigned
        /// Not in an Applications folder (a test copy, a build folder, a disk image).
        case notInstalled
        /// Run from a randomized read-only place macOS chose (App Translocation): moved by hand first.
        case translocated
        /// Its folder or itself cannot be written by this user.
        case readOnly

        /// What the update centre says.
        public var explanation: String {
            switch self {
                case .unsigned: "This build is not signed for updates."
                case .notInstalled: "Sunset updates itself once it is in an Applications folder."
                case .translocated: "macOS runs this copy from a temporary place: move Sunset to Applications first."
                case .readOnly: "Sunset cannot write where it is installed: update it from its releases page."
            }
        }
    }

    /// Why an app at `path`, signed by `team`, may not update itself; nil when it may.
    public static func refusal(path: String, team: String?, writable: Bool) -> Refusal? {
        guard team != nil else { return .unsigned }
        if path.contains("/AppTranslocation/") { return .translocated }
        let folders = path.split(separator: "/").dropLast()
        guard folders.contains("Applications") else { return .notInstalled }
        return writable ? nil : .readOnly
    }
}
