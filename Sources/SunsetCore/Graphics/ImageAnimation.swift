/// Animation playback state attached to a Kitty animated image (roadmap 0010 E).
public struct ImageAnimation: Sendable, Equatable {
    public enum State: UInt8, Sendable, Equatable {
        /// Stopped (`s=1`).
        case stopped = 1
        /// Loading / waiting for more frames (`s=2`).
        case loading = 2
        /// Playing normally (`s=3`).
        case running = 3
    }

    public var state: State = .stopped
    /// 1-based index of the currently displayed frame (`c`).
    public var currentFrame: Int = 1
    /// Number of loops (`v`): 0 = ignored, 1 = infinite, N > 1 = N - 1 loops.
    public var loops: Int = 1
    /// Additional frames (`index >= 2`) sorted by 1-based frame index. Frame 1 is the root `TerminalImage`.
    public var frames: [ImageFrame] = []
    /// Root frame (frame 1) display gap in milliseconds (`z`).
    public var rootGapMilliseconds: Int = 40

    public init() {}

    /// Total frames including the root frame (frame 1).
    public var frameCount: Int {
        1 + frames.count
    }

    /// The currently active extra frame when `currentFrame >= 2`, or nil when showing the root frame (frame 1).
    public var activeExtraFrame: ImageFrame? {
        guard currentFrame >= 2 else { return nil }
        return frames.first { $0.index == currentFrame }
    }

    /// Byte footprint of all extra frames stored in this animation.
    public var extraBytes: Int {
        frames.reduce(0) { $0 + $1.rgba.count }
    }
}
