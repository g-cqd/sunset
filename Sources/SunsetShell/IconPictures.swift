import AppKit

/// The icons of the picker's grid as small pictures, each rendered once, off the main actor: the system's symbols in
/// one colour, and emoji. Drawing a symbol's `NSImage` costs some 0.35 ms every time, kept or not (measured, release: 22
/// ms for the 63 in sight), and emoji drawn as text 4 ms a screen and 18 ms at worst; a picture is rendered once at about
/// that cost and drawn after as any image is. About 5 KB a symbol and 9 KB an emoji at 2x.
///
/// Pictures, not masks: a mask would be a quarter of the memory and take any colour, but a view on screen is drawn into a
/// context that records, and there neither a clip to a mask nor a stencil is dependable (seen 2026-11-17: a grid with no
/// symbol in it, then one that drew nothing at all).
@MainActor
final class IconPictures {
    struct Picture: @unchecked Sendable {
        let image: CGImage
        /// In points.
        let size: CGSize
    }

    private var pictures: [String: Picture] = [:]
    /// The names in the order they were kept: the oldest go first.
    private var order: [String] = []
    /// Names the system has no symbol for: not asked for again.
    private var absent: Set<String> = []
    private var scale: CGFloat = 2
    private var ink: [CGFloat] = [0, 0, 0, 1]
    private var rendering: Task<Void, Never>?
    /// How many are kept: some six screens of the grid, about two megabytes.
    private let limit = 400

    /// The pictures are of one scale and one colour (red, green, blue, alpha): another starts again.
    func use(scale new: CGFloat, ink colour: [CGFloat]) {
        guard new > 0, colour.count == 4, new != scale || colour != ink else { return }
        scale = new
        ink = colour
        rendering?.cancel()
        rendering = nil
        pictures.removeAll(keepingCapacity: true)
        order.removeAll(keepingCapacity: true)
    }

    /// The picture of the symbol called `name`, or of the emoji `name`, when it is kept. Nothing is rendered by asking: drawing never waits.
    func kept(_ name: String) -> Picture? {
        pictures[name]
    }

    /// Those of `names` still to render: not kept, and not known to be no symbol of the system.
    func missing(_ names: [String]) -> [String] {
        names.filter { pictures[$0] == nil && !absent.contains($0) }
    }

    private func keep(_ picture: Picture, as name: String) {
        guard pictures[name] == nil else { return }
        if order.count >= limit {
            for old in order.prefix(limit / 4) { pictures[old] = nil }
            order.removeFirst(limit / 4)
        }
        pictures[name] = picture
        order.append(name)
    }

    /// Renders the pictures of `names` that are missing, off the main actor and on several cores, then calls `done`. One
    /// request at a time: what is asked for while one runs is not taken, and is asked for again by the next drawing.
    /// - Parameters:
    ///   - names: the symbols wanted, the most wanted first; no more than are kept are taken.
    ///   - done: called on the main actor once they are kept; not called when nothing was missing or a request runs.
    func prepare(_ names: [String], then done: @escaping @MainActor () -> Void = {}) {
        guard rendering == nil else { return }
        let wanted = Array(missing(names).prefix(limit * 3 / 4))
        guard !wanted.isEmpty else { return }
        let (scale, ink) = (scale, ink)
        rendering = Task { [weak self] in
            let made = await Self.rendered(wanted, scale: scale, ink: ink)
            guard let self, !Task.isCancelled, self.scale == scale, self.ink == ink else { return }
            for (name, picture) in made {
                if let picture { self.keep(picture, as: name) } else { self.absent.insert(name) }
            }
            self.rendering = nil
            done()
        }
    }

    /// Sixteen symbols a task: a symbol takes about half a millisecond.
    @concurrent
    private static func rendered(_ names: [String], scale: CGFloat, ink: [CGFloat]) async -> [(String, Picture?)] {
        await withTaskGroup(of: [(String, Picture?)].self) { group in
            for start in stride(from: 0, to: names.count, by: 16) {
                let chunk = Array(names[start ..< min(start + 16, names.count)])
                group.addTask { chunk.map { ($0, render($0, scale: scale, ink: ink)) } }
            }
            var all: [(String, Picture?)] = []
            for await part in group { all += part }
            return all
        }
    }

    /// An emoji is not a symbol's name: those are letters, digits and dots.
    nonisolated static func isEmoji(_ name: String) -> Bool {
        name.unicodeScalars.first.map { !$0.isASCII } ?? false
    }

    /// An emoji drawn by Core Text into a bitmap of its own, centred in a square. On any thread.
    private nonisolated static func renderEmoji(_ text: String, scale: CGFloat) -> Picture? {
        let side: CGFloat = 24
        let pixels = Int((side * scale).rounded(.up))
        guard
            let context = CGContext(
                data: nil,
                width: pixels,
                height: pixels,
                bitsPerComponent: 8,
                bytesPerRow: pixels * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }
        let font = CTFontCreateWithName("AppleColorEmoji" as CFString, 18, nil)
        let string = NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
        )
        let line = CTLineCreateWithAttributedString(string)
        var (ascent, descent, leading): (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
        let width = unsafe CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        context.scaleBy(x: scale, y: scale)
        context.textPosition = CGPoint(x: (side - width) / 2, y: (side - ascent - descent) / 2 + descent)
        CTLineDraw(line, context)
        return context.makeImage().map { Picture(image: $0, size: CGSize(width: side, height: side)) }
    }

    /// The symbol drawn into a bitmap of its own, then every pixel it covers given the colour. On any thread.
    private nonisolated static func render(_ name: String, scale: CGFloat, ink: [CGFloat]) -> Picture? {
        if isEmoji(name) { return renderEmoji(name, scale: scale) }
        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        guard
            let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration)
        else { return nil }
        let size = image.size
        let (width, height) = (Int((size.width * scale).rounded(.up)), Int((size.height * scale).rounded(.up)))
        guard width > 0, height > 0,
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.current = previous
        context.restoreGState()
        // Where the symbol is, the colour; elsewhere nothing.
        context.setBlendMode(.sourceIn)
        context.setFillColor(red: ink[0], green: ink[1], blue: ink[2], alpha: ink[3])
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage().map { Picture(image: $0, size: size) }
    }

    /// Draws the icon centred on `centre` of a flipped view, when its picture is kept.
    /// - Returns: whether it was drawn.
    func paint(_ name: String, centredOn centre: CGPoint, in context: CGContext) -> Bool {
        guard let picture = pictures[name] else { return false }
        let rect = CGRect(
            x: (centre.x - picture.size.width / 2).rounded(),
            y: (centre.y - picture.size.height / 2).rounded(),
            width: picture.size.width,
            height: picture.size.height
        )
        context.saveGState()
        // The view is flipped and the picture is not.
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(picture.image, in: CGRect(origin: .zero, size: rect.size))
        context.restoreGState()
        return true
    }
}
