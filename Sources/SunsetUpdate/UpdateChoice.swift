/// Which release to offer (roadmap 0122 B): the latest build after the running one that publishes this flavour's archive
/// for this architecture; pre-releases only when the person takes them.
public enum UpdateChoice {
    /// The offer for the running app.
    /// - Parameters:
    ///   - releases: the feed's releases, in any order.
    ///   - flavour: which app is running.
    ///   - architecture: the archives' architecture (`arm64`).
    ///   - running: the running app's build (`CFBundleVersion`).
    ///   - prereleases: whether pre-releases count (the notes between are then theirs too).
    /// - Returns: the offer, or nil when nothing later is published for this app.
    public static func offer(
        in releases: [PublishedRelease],
        flavour: Flavour,
        architecture: String,
        running: Int,
        prereleases: Bool
    ) -> UpdateOffer? {
        let later = releases.filter { $0.build > running && (prereleases || !$0.prerelease) }
            .sorted { $0.build > $1.build }
        for (index, release) in later.enumerated() {
            if let archive = release.archive(for: flavour, architecture: architecture) {
                return UpdateOffer(release: release, archive: archive, between: Array(later[index...]))
            }
        }
        return nil
    }
}
