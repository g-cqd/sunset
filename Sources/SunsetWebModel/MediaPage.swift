package import Foundation

/// A page whose media plays, as its Now Playing card shows it (roadmap 0114).
package struct MediaPage: Equatable, Sendable, Identifiable {
    /// The page's pane content.
    package var id: UUID
    /// The media's title (`navigator.mediaSession`'s), else the page's.
    package var title: String
    package var artist: String?
    package var host: String
    /// The media's artwork, when the page names one.
    package var artwork: URL?
    package var hasVideo: Bool
    package var isPlaying: Bool
    package var isMuted: Bool

    package init(
        id: UUID,
        title: String,
        artist: String? = nil,
        host: String,
        artwork: URL? = nil,
        hasVideo: Bool = false,
        isPlaying: Bool,
        isMuted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.host = host
        self.artwork = artwork
        self.hasVideo = hasVideo
        self.isPlaying = isPlaying
        self.isMuted = isMuted
    }
}
