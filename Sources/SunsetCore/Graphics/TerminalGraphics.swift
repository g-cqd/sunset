/// A terminal's images and where they are shown (ADR-0117), kept by its screen: bounded by a quota in bytes and a number of
/// placements; and what is being received of a command sent in chunks.
public struct TerminalGraphics: Sendable {
    /// The images, by id.
    public internal(set) var images: [UInt32: TerminalImage] = [:]
    /// Where images are shown on the screen in use, oldest first.
    public internal(set) var placements: [ImagePlacement] = []
    /// The other screen's (the main screen's while the alternate is in use, and the other way round): each has its own.
    var otherPlacements: [ImagePlacement] = []
    /// What the images take, in bytes.
    public internal(set) var bytes = 0
    /// The most the images may take, in bytes (`Terminal.setGraphicsQuota`).
    var quota = 64 << 20
    /// A cell's size in pixels, as the host draws it (`Terminal.setCellPixelSize`): an image's cells are counted by it.
    var cellWidth = 8
    var cellHeight = 16
    /// What reads compressed images; nil: they are refused.
    var inflater: (any Inflater)?

    /// An APC string being collected, and whether it went over its bound.
    var collecting = false
    var overflowed = false
    var buffer = ContiguousArray<UInt8>()
    /// A command sent in chunks (`m=1`): its first chunk's control data, and the data decoded so far.
    var pending: (command: KittyCommand, data: [UInt8])?
    var stored: UInt64 = 0

    /// The most placements kept, the oldest going first.
    static let placementLimit = 4_096
    /// The most pixels an image may have a side.
    static let sideLimit = 10_000
    /// The most an APC string may hold before it is dropped (the parser's own bound is 1 MiB).
    static let stringLimit = 1 << 20

    /// Keeps `image`, sending the oldest away first while it would not fit; false when it is larger than the quota.
    mutating func store(_ image: TerminalImage) -> Bool {
        guard image.pixels.count <= quota else { return false }
        remove(image: image.id)
        // The oldest image no screen shows goes first, then the oldest of all (kitty does the same).
        while bytes + image.pixels.count > quota {
            let shown = Set((placements + otherPlacements).map(\.image))
            let unshown = images.values.filter { !shown.contains($0.id) }.min { $0.order < $1.order }
            guard let gone = unshown ?? images.values.min(by: { $0.order < $1.order }) else { break }
            remove(image: gone.id)
        }
        images[image.id] = image
        bytes += image.pixels.count
        return true
    }

    /// The image `id` and its placements gone.
    mutating func remove(image id: UInt32) {
        if let image = images.removeValue(forKey: id) { bytes -= image.pixels.count }
        placements.removeAll { $0.image == id }
        otherPlacements.removeAll { $0.image == id }
    }

    /// Whether any screen shows image `id`.
    func isShown(_ id: UInt32) -> Bool {
        placements.contains { $0.image == id } || otherPlacements.contains { $0.image == id }
    }

    mutating func place(_ placement: ImagePlacement) {
        if placement.placement != 0 {
            placements.removeAll { $0.image == placement.image && $0.placement == placement.placement }
        }
        placements.append(placement)
        if placements.count > Self.placementLimit { placements.removeFirst(placements.count - Self.placementLimit) }
    }

    /// Everything gone (a full reset).
    mutating func clear() {
        images = [:]
        placements = []
        otherPlacements = []
        bytes = 0
        pending = nil
    }

    /// The next order a stored image takes.
    mutating func nextOrder() -> UInt64 {
        stored += 1
        return stored
    }
}
