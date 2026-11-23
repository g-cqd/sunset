public import Foundation

/// An update from one build to another (roadmap 0122 C, ADR-0122): the new bundle's every item, each file either copied
/// from the running bundle (`copy`: the path of an equal file there) or made by a `BinaryDelta` (against the running file
/// at `base`, or against nothing for a new file).
///
/// Layout: `SSUPDAT1`, a little-endian 64-bit length, that many bytes of JSON (`Header`), then the deltas, which the
/// items locate by offset and length from the end of the JSON.
public struct UpdatePackage: Equatable, Sendable {
    public struct Item: Equatable, Sendable, Codable {
        public let entry: BundleEntry
        public let copy: String?
        public let base: String?
        public let offset: Int?
        public let length: Int?
    }

    struct Header: Codable {
        let from: Int
        let to: Int
        let items: [Item]
    }

    /// Why a package was refused.
    public enum Failure: Error, Equatable {
        case notAPackage
        case malformed
        /// An item would write outside the bundle (`..`, an absolute path).
        case outside(String)
    }

    static let magic = Data("SSUPDAT1".utf8)

    public let from: Int
    public let to: Int
    public let items: [Item]
    let deltas: Data

    /// The new bundle's manifest the package rebuilds.
    public var manifest: BundleManifest {
        BundleManifest(entries: items.map(\.entry))
    }

    /// The delta of `item`, within the package (checked when it was read).
    func delta(of item: Item) -> Data? {
        guard let offset = item.offset, let length = item.length else { return nil }
        return deltas.subdata(in: deltas.startIndex + offset ..< deltas.startIndex + offset + length)
    }
}
