extension PublishedRelease {
    /// The update package from build `from` to this release, when the release publishes one.
    public func package(for flavour: Flavour, from: Int, architecture: String) -> ReleaseAsset? {
        let name = Self.packageName(flavour: flavour, tag: tag, to: build, from: from, architecture: architecture)
        return assets.first { $0.name == name }
    }

    /// `<flavour>-<tag>-build<to>-from-build<from>-macos-<architecture>.update`.
    public static func packageName(flavour: Flavour, tag: String, to: Int, from: Int, architecture: String) -> String {
        "\(flavour.assetPrefix)\(tag)-build\(to)-from-build\(from)-macos-\(architecture).update"
    }
}
