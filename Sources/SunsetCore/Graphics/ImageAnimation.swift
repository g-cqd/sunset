/// The frames and playback state of a Kitty animated image (roadmap 0010 E), per the protocol's "Animation" section:
/// `s=1` stops (and resets the loop count), `s=2` runs in loading mode (waits at the last frame for more), `s=3` runs
/// and loops; `v=1` loops forever, `v=N` loops back N - 1 times; a frame with a negative gap is skipped.
public struct ImageAnimation: Sendable, Equatable {
    public enum State: UInt8, Sendable, Equatable {
        case stopped = 1
        case loading = 2
        case running = 3
    }

    /// The gap a frame has when none was given (`z=0` or absent), in milliseconds.
    public static let defaultGap = 40
    /// The most frames an image may have (the quota bounds their bytes; this bounds their count).
    public static let frameLimit = 4_096

    public var state: State = .stopped
    /// 1-based number of the frame shown.
    public var currentFrame = 1
    /// `v`: 1 (the default) loops forever, N > 1 loops back N - 1 times.
    public var loops = 1
    /// Times played back to the first frame since the animation was started.
    public var loopBacks = 0
    /// When the next frame is due, on the host's monotonic clock in milliseconds; nil until the first tick after
    /// starting, choosing a frame, or adding one while waiting.
    public var deadline: Int64?
    /// Frames 2 and up, in order: `frames[k]` is frame `k + 2`.
    public var frames: [ImageFrame] = []
    /// The root frame's gap (`a=a,r=1,z=…`).
    public var rootGapMilliseconds = defaultGap

    public init() {}

    /// Frames including the root.
    public var frameCount: Int {
        1 + frames.count
    }

    /// The frame shown when it is not the root.
    public var activeExtraFrame: ImageFrame? {
        currentFrame >= 2 && currentFrame - 2 < frames.count ? frames[currentFrame - 2] : nil
    }

    /// The gap of frame `number` (1-based).
    public func gap(of number: Int) -> Int {
        number <= 1 ? rootGapMilliseconds : frames[number - 2].gapMilliseconds
    }

    /// Bytes the extra frames hold.
    public var extraBytes: Int {
        frames.reduce(0) { $0 + $1.rgba.count }
    }
}
