/// A release to update to: the release, its archive for this app, and every release between the running build and it
/// (newest first, the offered one included) whose notes the update dialog shows.
public struct UpdateOffer: Equatable, Sendable {
    public let release: PublishedRelease
    public let archive: ReleaseAsset
    public let between: [PublishedRelease]

    public init(release: PublishedRelease, archive: ReleaseAsset, between: [PublishedRelease]) {
        self.release = release
        self.archive = archive
        self.between = between
    }
}
