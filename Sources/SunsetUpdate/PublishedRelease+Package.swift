extension PublishedRelease {
    /// The update package from build `from` to this release, when the release publishes one.
    public func package(for flavour: Flavour, from: Int, architecture: String) -> ReleaseAsset? {
        let name = Self.packageName(flavour: flavour, tag: tag, to: build, from: from, architecture: architecture)
        return assets.first { $0.name == name }
    }

    /// `<flavour>-<tag>-build<to>-from-build<from>-macos-<architecture>.update` (legacy v1 per-source package).
    public static func packageName(flavour: Flavour, tag: String, to: Int, from: Int, architecture: String) -> String {
        "\(flavour.assetPrefix)\(tag)-build\(to)-from-build\(from)-macos-\(architecture).update"
    }

    /// The single range-addressed delta archive (`SSDLTA2`, ADR-0125) for `flavour` and `architecture`.
    public func deltasArchive(for flavour: Flavour, architecture: String) -> ReleaseAsset? {
        let name = Self.deltasArchiveName(flavour: flavour, tag: tag, build: build, architecture: architecture)
        return assets.first { $0.name == name }
    }

    /// `<flavour>-<tag>-build<build>-macos-<architecture>.deltas`.
    public static func deltasArchiveName(flavour: Flavour, tag: String, build: Int, architecture: String) -> String {
        "\(flavour.assetPrefix)\(tag)-build\(build)-macos-\(architecture).deltas"
    }

    /// The signed release index (`release-index.json`) and its Ed25519 signature (`release-index.json.sig`), when published.
    public var signedIndexAssets: (index: ReleaseAsset, signature: ReleaseAsset)? {
        guard let index = assets.first(where: { $0.name == ReleaseIndex.assetName }),
            let sig = assets.first(where: { $0.name == ReleaseIndex.signatureAssetName })
        else { return nil }
        return (index, sig)
    }
}
