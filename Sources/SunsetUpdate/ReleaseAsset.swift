public import Foundation

/// A file published with a release: its name, its size and where it downloads from.
public struct ReleaseAsset: Equatable, Sendable, Decodable {
    public let name: String
    public let size: Int
    public let url: URL

    public init(name: String, size: Int, url: URL) {
        self.name = name
        self.size = size
        self.url = url
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case size
        case url = "browser_download_url"
    }
}
