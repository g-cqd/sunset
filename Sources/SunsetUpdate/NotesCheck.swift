internal import Foundation

/// Whether a release's notes are the ones its signed index names (ADR-0125): the update window shows notes that match, says
/// so of releases from before signed indexes, and withholds notes that do not match.
public enum NotesCheck: Equatable, Sendable {
    /// The notes hash to the signed index's `notesSHA256`.
    case verified
    /// The release has no signed index, and was published before releases had one.
    case unsigned
    /// The notes are not the ones the signed index names; or its signature failed; or a release that must have an index
    /// has none.
    case mismatch

    /// The first build published with a signed index (v0.1.0-alpha.13): any later release without one is not trusted.
    public static let firstSignedBuild = 829

    /// Checks `notes` (the release's body, as GitHub returns it) against `index`, for the release of `build`.
    public static func of(notes: String, index: ReleaseIndex?, build: Int) -> Self {
        guard let index else { return build >= firstSignedBuild ? .mismatch : .unsigned }
        return BundleManifest.hex(Data(notes.utf8)) == index.notesSHA256 ? .verified : .mismatch
    }

    /// The title the window shows for the release: GitHub's, unless the release failed its check, whose title (not
    /// covered by the signature) is not shown as given.
    public func title(given: String, build: Int) -> String {
        self == .mismatch ? "Unverified release (build \(build))" : given
    }

    /// Whether the window shows the notes.
    public var showsNotes: Bool {
        self != .mismatch
    }
}
