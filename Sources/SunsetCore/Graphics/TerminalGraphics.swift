/// A terminal's images and where they are shown (ADR-0117), kept by its screen: bounded by a quota in bytes and a number of
/// placements; and what is being received of a command sent in chunks.
public struct TerminalGraphics: Sendable {
    /// The images, by id.
    public internal(set) var images: [UInt32: TerminalImage] = [:]
    /// Where images are shown on the screen in use, oldest first.
    public internal(set) var placements: [ImagePlacement] = []
    /// The other screen's (the main screen's while the alternate is in use, and the other way round): each has its own.
    var otherPlacements: [ImagePlacement] = []
    /// Images placed for placeholder cells to draw (`U=1`, roadmap 0010 E), oldest first: the cells are on either screen.
    public internal(set) var virtualPlacements: [VirtualPlacement] = []
    /// What the images take, in bytes.
    public internal(set) var bytes = 0
    /// The most the images may take, in bytes (`Terminal.setGraphicsQuota`).
    var quota = 64 << 20
    /// A cell's size in pixels, as the host draws it (`Terminal.setCellPixelSize`): an image's cells are counted by it.
    var cellWidth = 8
    var cellHeight = 16
    /// What reads compressed images; nil: they are refused.
    var inflater: (any Inflater)?

    /// A string buffer for either Kitty APC (`G...`) or Sixel DCS (`DCS ... q`).
    enum CollectingKind: Sendable, Equatable {
        case none, kitty, sixel
    }

    var collectingKind = CollectingKind.none
    var sixelTransparent = false
    var overflowed = false
    var buffer = ContiguousArray<UInt8>()
    /// A command sent in chunks (`m=1`): its first chunk's control data, and the data decoded so far.
    var pending: (command: KittyCommand, data: [UInt8])?
    var stored: UInt64 = 0

    /// The most placements kept, the oldest going first; virtual placements too.
    static let placementLimit = 4_096
    /// The most pixels an image may have a side.
    static let sideLimit = 10_000
    /// The most an APC string may hold before it is dropped (the parser's own bound is 1 MiB).
    static let stringLimit = 1 << 20
    /// Maximum bytes buffered for one Sixel DCS stream (8 MiB).
    static let sixelLimit = 8 << 20

    /// Keeps `image`, sending the oldest away first while it would not fit; false when it is larger than the quota.
    mutating func store(_ image: TerminalImage) -> Bool {
        let cost = image.byteCount
        guard cost <= quota else { return false }
        remove(image: image.id)
        // The oldest image no screen shows goes first, then the oldest of all (kitty does the same).
        while bytes + cost > quota {
            let shown = Set((placements + otherPlacements).map(\.image) + virtualPlacements.map(\.image))
            let unshown = images.values.filter { !shown.contains($0.id) }.min { $0.order < $1.order }
            guard let gone = unshown ?? images.values.min(by: { $0.order < $1.order }) else { break }
            remove(image: gone.id)
        }
        images[image.id] = image
        bytes += cost
        return true
    }

    /// Updates an existing image in place (e.g. adding or composing an animation frame), enforcing `quota`.
    mutating func update(_ image: TerminalImage) -> Bool {
        let oldCost = images[image.id]?.byteCount ?? 0
        let newCost = image.byteCount
        let delta = newCost - oldCost
        guard delta <= 0 || bytes + delta <= quota else { return false }
        images[image.id] = image
        bytes += delta
        return true
    }

    /// Resolves a Kitty image id from `i=` (explicit id) or `I=` (newest image bearing that image number).
    func resolveID(id: Int, number: Int) -> UInt32? {
        if id > 0 { return UInt32(clamping: id) }
        guard number > 0 else { return nil }
        let target = UInt32(clamping: number)
        return images.values.filter { $0.number == target }.max { $0.order < $1.order }?.id
    }

    /// Allocates a fresh non-colliding image id (for anonymous Sixel, iTerm2, or `I=` Kitty images).
    mutating func nextAnonymousID() -> UInt32 {
        var candidate = UInt32.max &- UInt32(truncatingIfNeeded: stored)
        while candidate == 0 || images[candidate] != nil {
            stored &+= 1
            candidate = UInt32.max &- UInt32(truncatingIfNeeded: stored)
        }
        return candidate
    }

    /// The image `id` and its placements gone.
    mutating func remove(image id: UInt32) {
        if let image = images.removeValue(forKey: id) { bytes -= image.byteCount }
        placements.removeAll { $0.image == id }
        otherPlacements.removeAll { $0.image == id }
        virtualPlacements.removeAll { $0.image == id }
    }

    /// Whether any screen shows image `id`, or placeholder cells may.
    func isShown(_ id: UInt32) -> Bool {
        placements.contains { $0.image == id } || otherPlacements.contains { $0.image == id }
            || virtualPlacements.contains { $0.image == id }
    }

    /// Keeps `virtual`, in place of the one with its image and number (any of its image's, when it has no number).
    mutating func place(virtual: VirtualPlacement) {
        virtualPlacements.removeAll { $0.image == virtual.image && $0.placement == virtual.placement }
        virtualPlacements.append(virtual)
        if virtualPlacements.count > Self.placementLimit {
            virtualPlacements.removeFirst(virtualPlacements.count - Self.placementLimit)
        }
    }

    /// The virtual placement placeholder cells naming `image` and `placement` draw: that one, or for no number the last of the
    /// image's (kitty takes any).
    func virtual(image: UInt32, placement: UInt32) -> VirtualPlacement? {
        virtualPlacements.last { $0.image == image && (placement == 0 || $0.placement == placement) }
    }

    mutating func place(_ placement: ImagePlacement) {
        if placement.placement != 0 {
            placements.removeAll { $0.image == placement.image && $0.placement == placement.placement }
        }
        placements.append(placement)
        if placements.count > Self.placementLimit { placements.removeFirst(placements.count - Self.placementLimit) }
    }

    /// Shifts alternate-screen placements when the alternate screen scrolls up (`delta < 0`) or down (`delta > 0`),
    /// dropping placements that scroll completely above the screen.
    mutating func shiftAlternatePlacements(by delta: Int, screenTopStable: Int) {
        guard delta != 0, !placements.isEmpty else { return }
        var kept: [ImagePlacement] = []
        kept.reserveCapacity(placements.count)
        for p in placements where p.stableLine + delta + p.rows > screenTopStable {
            var moved = p
            moved.stableLine += delta
            kept.append(moved)
        }
        placements = kept
    }

    /// Everything gone (a full reset).
    mutating func clear() {
        images = [:]
        placements = []
        otherPlacements = []
        virtualPlacements = []
        bytes = 0
        pending = nil
    }

    /// The next order a stored image takes.
    mutating func nextOrder() -> UInt64 {
        stored += 1
        return stored
    }
}
