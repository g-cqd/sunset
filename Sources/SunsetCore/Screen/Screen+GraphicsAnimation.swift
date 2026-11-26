/// Kitty graphics animation (`a=f` transmit frame, `a=a` animation control, `a=c` compose frame — roadmap 0010 E).
/// Keeps every frame decoded as straight RGBA matching the root canvas, respects `TerminalGraphics.quota`, and replies
/// with the same `i=` / `I=` / `q=` contract as static Kitty commands.
extension Screen {
    /// Finishes an `a=f` frame upload once all chunks have arrived and been inflated (`Screen+GraphicsTransmit.swift`).
    mutating func finishFrame(_ command: KittyCommand, _ data: [UInt8]) {
        guard let root = resolvedAnimationRoot(for: command) else { return }
        let format = command.int("f", or: 32)
        guard format == 24 || format == 32 else { return kittyReply(command, .invalid) }
        let channels = format == 24 ? 3 : 4
        let size = Self.frameDimensions(command, fallback: (root.width, root.height), widthKey: "s", heightKey: "v")
        guard size.width > 0, size.height > 0, size.width <= TerminalGraphics.sideLimit,
            size.height <= TerminalGraphics.sideLimit, data.count >= size.width * size.height * channels
        else { return kittyReply(command, .noData) }

        var anim = root.animation ?? ImageAnimation()
        var canvas = ImageFrameBlit.baseCanvas(
            for: root,
            anim: anim,
            baseFrame: command.int("c"),
            background: command.int("Y")
        )
        ImageFrameBlit.blitCommand(
            command,
            source: ImageFrameBlit.CommandBlit(
                bytes: data,
                channels: channels,
                stride: size.width,
                width: size.width,
                height: size.height,
                isCompose: false
            ),
            into: &canvas,
            canvas: (root.width, root.height)
        )
        let gap = command.int("z") == 0 ? 40 : command.int("z")
        let editNumber = command.int("r")
        let targetIndex = editNumber >= 1 ? editNumber : anim.frameCount + 1
        if targetIndex == 1 { anim.rootGapMilliseconds = gap }
        guard applyFramePixels(canvas, gap: gap, to: targetIndex, root: root, anim: anim) else {
            return kittyReply(command, .noSpace)
        }
        markDirty(0 ... rows - 1)
        kittyReply(command, nil)
    }

    /// Handles `a=a` (animation control): start/stop/loading (`s`), set current frame (`c`), set gap (`r`/`z`), loops (`v`).
    mutating func controlAnimation(_ command: KittyCommand) {
        guard var root = resolvedAnimationRoot(for: command) else { return }
        var anim = root.animation ?? ImageAnimation()
        if let state = ImageAnimation.State(rawValue: UInt8(clamping: command.int("s"))) { anim.state = state }
        if command.int("v") > 0 { anim.loops = command.int("v") }
        let (frameToEdit, gap) = (command.int("r"), command.int("z"))
        if frameToEdit == 1, gap != 0 {
            anim.rootGapMilliseconds = gap
        } else if frameToEdit >= 2, gap != 0, let idx = anim.frames.firstIndex(where: { $0.index == frameToEdit }) {
            anim.frames[idx].gapMilliseconds = gap
        }
        let requestedFrame = command.int("c")
        if requestedFrame >= 1, requestedFrame <= anim.frameCount { anim.currentFrame = requestedFrame }
        root.animation = anim
        _ = graphics.update(root)
        markDirty(0 ... rows - 1)
        kittyReply(command, nil)
    }

    /// Handles `a=c` (compose pixels from source frame `r` into destination frame `c`).
    mutating func composeFrame(_ command: KittyCommand) {
        guard let root = resolvedAnimationRoot(for: command), let anim = root.animation else { return }
        let (srcIndex, dstIndex) = (command.int("r"), command.int("c"))
        guard srcIndex >= 1, dstIndex >= 1, srcIndex <= anim.frameCount, dstIndex <= anim.frameCount else {
            return kittyReply(command, .noEntry)
        }
        let srcCanvas = ImageFrameBlit.rgbaPixels(of: root, anim: anim, frame: srcIndex)
        var dstCanvas = ImageFrameBlit.rgbaPixels(of: root, anim: anim, frame: dstIndex)
        let size = Self.frameDimensions(command, fallback: (root.width, root.height), widthKey: "w", heightKey: "h")
        ImageFrameBlit.blitCommand(
            command,
            source: ImageFrameBlit.CommandBlit(
                bytes: srcCanvas,
                channels: 4,
                stride: root.width,
                width: size.width,
                height: size.height,
                isCompose: true
            ),
            into: &dstCanvas,
            canvas: (root.width, root.height)
        )
        let existingGap = anim.frames.first { $0.index == dstIndex }?.gapMilliseconds ?? anim.rootGapMilliseconds
        _ = applyFramePixels(dstCanvas, gap: existingGap, to: dstIndex, root: root, anim: anim)
        markDirty(0 ... rows - 1)
        kittyReply(command, nil)
    }

    private static func frameDimensions(
        _ command: KittyCommand,
        fallback: (width: Int, height: Int),
        widthKey: Unicode.Scalar,
        heightKey: Unicode.Scalar
    ) -> (width: Int, height: Int) {
        let w = command.int(widthKey)
        let h = command.int(heightKey)
        return (w > 0 ? w : fallback.width, h > 0 ? h : fallback.height)
    }

    private mutating func resolvedAnimationRoot(for command: KittyCommand) -> TerminalImage? {
        guard let id = graphics.resolveID(id: command.int("i"), number: command.int("I")),
            let root = graphics.images[id]
        else {
            kittyReply(command, .noEntry)
            return nil
        }
        return root
    }

    private mutating func applyFramePixels(
        _ pixels: [UInt8],
        gap: Int,
        to targetIndex: Int,
        root: TerminalImage,
        anim initialAnim: ImageAnimation
    ) -> Bool {
        var anim = initialAnim
        if targetIndex == 1 {
            let updated = TerminalImage(
                id: root.id,
                number: root.number,
                format: .rgba,
                width: root.width,
                height: root.height,
                pixels: pixels,
                order: graphics.nextOrder(),
                animation: anim
            )
            return graphics.update(updated)
        }
        let frame = ImageFrame(
            index: targetIndex,
            gapMilliseconds: gap,
            width: root.width,
            height: root.height,
            rgba: pixels
        )
        if let existing = anim.frames.firstIndex(where: { $0.index == targetIndex }) {
            anim.frames[existing] = frame
        } else {
            anim.frames.append(frame)
            anim.frames.sort { $0.index < $1.index }
        }
        var updatedRoot = root
        updatedRoot.animation = anim
        return graphics.update(updatedRoot)
    }
}
