/// Kitty graphics animation (roadmap 0010 E), per the protocol's "Animation" section: `a=f` loads a frame or edits one
/// (`r`), composed onto a frame (`c`), the frame being edited, or a colour (`Y`), by alpha blending or replacement (`X=1`);
/// `a=a` controls playback (`s`, `v`, `c`, `r`+`z`); `a=c` composes a rectangle of frame `r` (at `X,Y`) onto frame `c`
/// (at `x,y`). Frames are kept as straight RGBA of the root's size. A PNG root's pixels are not decoded here, so a
/// command that would read or rewrite them is refused (`EINVAL`) rather than composed onto a blank canvas.
extension Screen {
    mutating func finishFrame(_ command: KittyCommand, _ data: [UInt8]) {
        guard var (root, anim) = animated(command, frames: "rc", from: 0) else { return }
        let format = command.int("f", or: 32)
        guard format == 24 || format == 32 else { return kittyReply(command, .invalid) }
        let (edit, base) = (command.int("r"), command.int("c"))
        guard edit != 0 || anim.frameCount < ImageAnimation.frameLimit else { return kittyReply(command, .noSpace) }
        let rect = Rect(
            x: command.int("x"),
            y: command.int("y"),
            width: command.int("s") > 0 ? command.int("s") : root.width,
            height: command.int("v") > 0 ? command.int("v") : root.height
        )
        guard rect.fits(root) else { return kittyReply(command, .invalid) }
        let channels = format / 8
        guard data.count >= rect.width * rect.height * channels else { return kittyReply(command, .noData) }
        // The canvas: the frame being edited, else the frame named by `c`, else the background colour.
        let canvasFrame = edit != 0 ? edit : base
        guard canvasFrame != 1 || root.format != .png else { return kittyReply(command, .invalid) }
        var canvas =
            canvasFrame != 0
            ? ImageFrameBlit.rgbaPixels(of: root, anim: anim, frame: canvasFrame)
            : ImageFrameBlit.filledCanvas(width: root.width, height: root.height, background: command.int("Y"))
        Self.blit(
            Pixels(bytes: data, channels: channels, stride: rect.width),
            from: Rect(x: 0, y: 0, width: rect.width, height: rect.height),
            onto: &canvas,
            at: rect,
            of: root,
            blend: command.int("X") != 1
        )
        let given = command.int("z")
        let target = edit != 0 ? edit : anim.frameCount + 1
        let gap = given != 0 ? given : (edit != 0 ? anim.gap(of: edit) : ImageAnimation.defaultGap)
        if target == 1 { anim.rootGapMilliseconds = gap }
        // A frame added while the animation waits at the last one (loading mode) is shown on the next tick.
        if edit == 0, anim.state == .loading, anim.currentFrame == anim.frameCount { anim.deadline = nil }
        finish(command, storing: canvas, gap: gap, as: target, in: &root, anim: anim)
    }

    mutating func controlAnimation(_ command: KittyCommand) {
        guard var (root, anim) = animated(command, frames: "rc", from: 0) else { return }
        let (edit, gap, frame) = (command.int("r"), command.int("z"), command.int("c"))
        if let state = ImageAnimation.State(rawValue: UInt8(clamping: command.int("s"))), state != anim.state {
            if state == .stopped { anim.loopBacks = 0 }
            if anim.state == .stopped { anim.deadline = nil }
            anim.state = state
        }
        if command.int("v") > 0 { anim.loops = command.int("v") }
        if edit == 1, gap != 0 { anim.rootGapMilliseconds = gap }
        if edit >= 2, gap != 0 { anim.frames[edit - 2].gapMilliseconds = gap }
        if frame != 0 {
            anim.currentFrame = frame
            anim.deadline = nil
        }
        root.animation = anim
        _ = graphics.update(root)
        markShown(root.id)
        kittyReply(command, nil)
    }

    mutating func composeFrame(_ command: KittyCommand) {
        guard let found = animated(command, frames: "rc", from: 1) else { return }
        var root = found.0
        let anim = found.1
        let (from, onto) = (command.int("r"), command.int("c"))
        let width = command.int("w") > 0 ? command.int("w") : root.width
        let height = command.int("h") > 0 ? command.int("h") : root.height
        let source = Rect(x: command.int("X"), y: command.int("Y"), width: width, height: height)
        let destination = Rect(x: command.int("x"), y: command.int("y"), width: width, height: height)
        guard source.fits(root), destination.fits(root), from != onto || !source.overlaps(destination),
            root.format != .png || (from != 1 && onto != 1)
        else { return kittyReply(command, .invalid) }
        var canvas = ImageFrameBlit.rgbaPixels(of: root, anim: anim, frame: onto)
        let pixels = ImageFrameBlit.rgbaPixels(of: root, anim: anim, frame: from)
        Self.blit(
            Pixels(bytes: pixels, channels: 4, stride: root.width),
            from: source,
            onto: &canvas,
            at: destination,
            of: root,
            blend: command.int("C") != 1
        )
        finish(command, storing: canvas, gap: anim.gap(of: onto), as: onto, in: &root, anim: anim)
    }

    /// A rectangle of pixels, as the protocol's keys give it.
    private struct Rect {
        let x: Int
        let y: Int
        let width: Int
        let height: Int

        func fits(_ image: TerminalImage) -> Bool {
            x >= 0 && y >= 0 && width > 0 && height > 0 && width <= image.width - x && height <= image.height - y
        }

        func overlaps(_ other: Rect) -> Bool {
            x < other.x + other.width && other.x < x + width && y < other.y + other.height && other.y < y + height
        }
    }

    /// The image `i` or `I` names and its animation, when each frame number the keys in `keys` give is `minimum` or a
    /// frame of it (0 meaning "not given"); answered `ENOENT` and nil otherwise.
    private mutating func animated(
        _ command: KittyCommand,
        frames keys: String,
        from minimum: Int
    ) -> (TerminalImage, ImageAnimation)? {
        guard let id = graphics.resolveID(id: command.int("i"), number: command.int("I")),
            let root = graphics.images[id]
        else {
            kittyReply(command, .noEntry)
            return nil
        }
        let anim = root.animation ?? ImageAnimation()
        for key in keys.unicodeScalars where !(minimum ... anim.frameCount).contains(command.int(key)) {
            kittyReply(command, .noEntry)
            return nil
        }
        return (root, anim)
    }

    /// Pixels to copy: their bytes, 3 or 4 a pixel, in rows of `stride` pixels.
    private struct Pixels {
        let bytes: [UInt8]
        let channels: Int
        let stride: Int
    }

    /// The pixels in rectangle `from` of `pixels` put at rectangle `at` of the root-sized canvas.
    private static func blit(
        _ pixels: Pixels,
        from source: Rect,
        onto canvas: inout [UInt8],
        at destination: Rect,
        of root: TerminalImage,
        blend: Bool
    ) {
        ImageFrameBlit.blit(
            ImageFrameBlit.Source(
                bytes: pixels.bytes,
                channels: pixels.channels,
                stride: pixels.stride,
                x: source.x,
                y: source.y,
                width: source.width,
                height: source.height
            ),
            into: &canvas,
            target: ImageFrameBlit.Target(
                width: root.width,
                height: root.height,
                x: destination.x,
                y: destination.y,
                alphaBlend: blend
            )
        )
    }

    /// Keeps `pixels` as frame `number`, marks where the image is shown, and answers: OK, or `ENOSPC` when the quota
    /// refuses it.
    private mutating func finish(
        _ command: KittyCommand,
        storing pixels: [UInt8],
        gap: Int,
        as number: Int,
        in root: inout TerminalImage,
        anim: ImageAnimation
    ) {
        guard store(pixels, gap: gap, as: number, in: &root, anim: anim) else { return kittyReply(command, .noSpace) }
        markShown(root.id)
        kittyReply(command, nil)
    }

    /// `pixels` kept as frame `number` (the root when 1, a new last frame when one past the end), with a new revision
    /// so nothing drawn from the old pixels is reused; false when the quota refuses it.
    private mutating func store(
        _ pixels: [UInt8],
        gap: Int,
        as number: Int,
        in root: inout TerminalImage,
        anim initial: ImageAnimation
    ) -> Bool {
        var updated = root
        var anim = initial
        if number == 1 {
            updated = TerminalImage(
                id: root.id,
                number: root.number,
                format: .rgba,
                width: root.width,
                height: root.height,
                pixels: pixels,
                order: graphics.nextOrder(),
                animation: anim
            )
        } else {
            let frame = ImageFrame(
                index: number,
                gapMilliseconds: gap,
                width: root.width,
                height: root.height,
                rgba: pixels,
                revision: graphics.nextOrder()
            )
            if number - 2 < anim.frames.count { anim.frames[number - 2] = frame } else { anim.frames.append(frame) }
            updated.animation = anim
        }
        guard graphics.update(updated) else { return false }
        root = updated
        return true
    }
}
