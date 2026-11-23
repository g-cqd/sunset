public import Foundation

/// GitHub's list of releases (`api.github.com/repos/<owner>/<repo>/releases`) read into `PublishedRelease`s, newest first
/// as GitHub lists them. Drafts and releases whose assets say no build are left out (ADR-0122).
public enum ReleaseFeed {
    /// Where Sunset's releases are listed: its own repository, without an account.
    public static let address = URL(string: "https://api.github.com/repos/g-cqd/sunset/releases?per_page=30")

    /// The releases in `data`; throws when it is not a list of releases (GitHub's error objects included).
    public static func decode(_ data: Data) throws -> [PublishedRelease] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Listed].self, from: data)
            .compactMap { listed in
                guard !listed.draft,
                    let build = listed.assets.lazy.compactMap({ PublishedRelease.build(in: $0.name) }).first
                else { return nil }
                return PublishedRelease(
                    tag: listed.tag,
                    title: listed.name ?? listed.tag,
                    build: build,
                    prerelease: listed.prerelease,
                    notes: listed.body ?? "",
                    published: listed.published,
                    assets: listed.assets
                )
            }
    }

    /// A release as the API lists it.
    private struct Listed: Decodable {
        let tag: String
        let name: String?
        let draft: Bool
        let prerelease: Bool
        let body: String?
        let published: Date?
        let assets: [ReleaseAsset]

        private enum CodingKeys: String, CodingKey {
            case name, draft, prerelease, body, assets
            case tag = "tag_name"
            case published = "published_at"
        }
    }
}
