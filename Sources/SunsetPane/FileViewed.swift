/// What a file only looked at is, by its extension: how its viewer draws it.
public enum FileViewed: String, Sendable, CaseIterable {
    case pdf, picture, media

    public init?(extension name: String) {
        guard let found = Self.byExtension[name.lowercased()] else { return nil }
        self = found
    }

    /// Each kind's extensions.
    private static let byExtension: [String: Self] = [
        (Self.pdf, "pdf"),
        (Self.picture, "png jpg jpeg gif heic heif webp tif tiff bmp ico avif"),
        (Self.media, "mp4 m4v mov mp3 m4a aac wav aiff aif caf flac")
    ]
    .reduce(into: [:]) { table, entry in
        for name in entry.1.split(separator: " ") { table[String(name)] = entry.0 }
    }
}
