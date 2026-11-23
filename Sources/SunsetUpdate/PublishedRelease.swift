public import Foundation

/// A release of Sunset as GitHub lists it: its tag, its build (the count `make-app.sh` writes as `CFBundleVersion`, which
/// orders releases), whether it is a pre-release, its notes and its assets.
public struct PublishedRelease: Equatable, Sendable {
    public let tag: String
    public let title: String
    public let build: Int
    public let prerelease: Bool
    public let notes: String
    public let published: Date?
    public let assets: [ReleaseAsset]

    public init(
        tag: String,
        title: String,
        build: Int,
        prerelease: Bool,
        notes: String,
        published: Date?,
        assets: [ReleaseAsset]
    ) {
        self.tag = tag
        self.title = title
        self.build = build
        self.prerelease = prerelease
        self.notes = notes
        self.published = published
        self.assets = assets
    }

    /// The archive of `flavour` for `architecture`: `<flavour>-<tag>-build<build>-macos-<architecture>.zip`.
    public func archive(for flavour: Flavour, architecture: String) -> ReleaseAsset? {
        let name = "\(flavour.assetPrefix)\(tag)-build\(build)-macos-\(architecture).zip"
        return assets.first { $0.name == name }
    }

    /// The build an asset's name says (`…-build786-…`), nil when it says none.
    static func build(in name: String) -> Int? {
        guard let range = name.range(of: "-build") else { return nil }
        let digits = name[range.upperBound...].prefix { $0.isASCII && $0.isNumber }
        return Int(digits)
    }
}
