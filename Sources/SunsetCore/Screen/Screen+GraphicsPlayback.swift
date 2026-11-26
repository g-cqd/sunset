/// Terminal-driven Kitty animation playback (roadmap 0010 E). The core keeps no clock: the host calls
/// `advanceAnimations(nowMilliseconds:)` with its monotonic time, and is told when to call again. Only animations of
/// images on screen advance, one frame per due tick (a host that was away resumes where it was, it does not race through
/// the frames it missed), gapless frames are skipped, and a frame whose deadline was missed by more than its gap is
/// timed afresh from now.
extension Screen {
    /// What a tick did: whether a frame changed (draw), and when the next frame is due (nil: nothing is running).
    public struct AnimationTick: Sendable, Equatable {
        public let changed: Bool
        public let next: Int64?
    }

    public mutating func advanceAnimations(nowMilliseconds now: Int64) -> AnimationTick {
        var changed = false
        var next: Int64?
        for id in graphics.images.keys.sorted() {
            guard var image = graphics.images[id], var anim = image.animation, anim.state != .stopped,
                anim.frameCount > 1, graphics.isShown(id)
            else { continue }
            if let due = anim.deadline, now >= due, let frame = Self.nextFrame(after: anim) {
                if frame.wrapped { anim.loopBacks += 1 }
                if frame.number != anim.currentFrame {
                    anim.currentFrame = frame.number
                    changed = true
                    markShown(id)
                }
                let gap = Int64(max(anim.gap(of: frame.number), 0))
                anim.deadline = due + gap > now ? due + gap : now + gap
            } else if let due = anim.deadline, now >= due {
                // At the end: stopped by the loop count (which resets it, as a stop does), or waiting for more frames
                // in loading mode.
                if anim.state == .running {
                    anim.state = .stopped
                    anim.loopBacks = 0
                } else {
                    anim.deadline = now + Int64(ImageAnimation.defaultGap)
                }
            } else if anim.deadline == nil {
                anim.deadline = now + Int64(max(anim.gap(of: anim.currentFrame), 0))
            }
            if anim.state != .stopped, let due = anim.deadline { next = min(next ?? due, due) }
            // Written back only when the playback moved: an untouched entry is not copied out of a shared snapshot.
            if anim.currentFrame != image.animation?.currentFrame || anim.deadline != image.animation?.deadline
                || anim.state != image.animation?.state || anim.loopBacks != image.animation?.loopBacks
            {
                image.animation = anim
                graphics.images[id] = image
            }
        }
        return AnimationTick(changed: changed, next: next)
    }

    /// The frame after the current one that is shown (gapless frames skipped), and whether it is reached by playing
    /// back to the first; nil at the end of the frames when the animation may not loop (loading mode, or the loops
    /// spent), or when every frame is gapless.
    static func nextFrame(after anim: ImageAnimation) -> (number: Int, wrapped: Bool)? {
        var number = anim.currentFrame
        var wrapped = false
        for _ in 0 ..< anim.frameCount {
            if number >= anim.frameCount {
                guard anim.state == .running, anim.loops == 1 || anim.loopBacks + (wrapped ? 1 : 0) < anim.loops - 1
                else { return nil }
                number = 1
                wrapped = true
            } else {
                number += 1
            }
            if anim.gap(of: number) >= 0 { return (number, wrapped) }
        }
        return nil
    }

    /// Marks for redrawing the rows where image `id` is shown: its placements' rows on the live screen, row 0 when a
    /// placement is in the history only (a viewport scrolled back redraws whole on any mark), every row when
    /// placeholder cells may show it.
    mutating func markShown(_ id: UInt32) {
        if graphics.virtualPlacements.contains(where: { $0.image == id }) { return markDirty(0 ... rows - 1) }
        for placement in graphics.placements where placement.image == id {
            guard let line = absoluteLine(ofStable: placement.stableLine) else { continue }
            let top = line - scrollback.count
            let bottom = top + placement.rows - 1
            if bottom < 0 { markDirty(0) } else if top < rows { markDirty(max(top, 0) ... min(bottom, rows - 1)) }
        }
    }
}
