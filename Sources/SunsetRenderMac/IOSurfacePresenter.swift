internal import CoreGraphics
public import IOSurface
public import SunsetRender
internal import Synchronization

/// Keeps each frame in an `IOSurface`, which a layer shows as its contents and the compositor reads on the GPU, so that no frame is turned into an image
/// and colour-converted on the CPU (that conversion was most of an idle window's cost). The surfaces are tagged sRGB, which is what the renderer draws in.
///
/// Three surfaces take turns: the one just shown is never written (the compositor may still be reading it). Each surface remembers which rows it has missed
/// (the frames written to the others since it was written) and gets those and the new ones: a frame costs the rows that changed, not the window.
public final class IOSurfacePresenter: FramePresenter, Sendable {
    private static let bufferCount = 3
    /// 'RGBA': the bytes of a pixel are red, green, blue, alpha, as the renderer packs them.
    private static let pixelFormat: Int32 = 0x5247_4241

    private struct State {
        var buffers: [IOSurface] = []
        /// Per buffer, the rows it lacks (frames written to the other buffers since).
        var missing: [ClosedRange<Int>?] = []
        var shown: Int?
        var size = (width: 0, height: 0)
    }

    private let state = Mutex(State())

    public init() {}

    /// The surface that holds the latest frame; nil before the first.
    public var latest: IOSurface? {
        state.withLock { state in state.shown.map { state.buffers[$0] } }
    }

    public func present(_ surface: Surface, changedRows: ClosedRange<Int>) {
        state.withLock { state in
            if state.size != (surface.width, surface.height) || state.buffers.isEmpty {
                guard make(&state, width: surface.width, height: surface.height) else { return }
            }
            let target = ((state.shown ?? Self.bufferCount - 1) + 1) % Self.bufferCount
            let rows = merge(state.missing[target], changedRows)
            copy(surface, rows: rows, into: state.buffers[target])
            state.missing[target] = nil
            for other in 0 ..< Self.bufferCount where other != target {
                state.missing[other] = merge(state.missing[other], changedRows)
            }
            state.shown = target
        }
    }

    private func merge(_ first: ClosedRange<Int>?, _ second: ClosedRange<Int>) -> ClosedRange<Int> {
        guard let first else { return second }
        return min(first.lowerBound, second.lowerBound) ... max(first.upperBound, second.upperBound)
    }

    private func make(_ state: inout State, width: Int, height: Int) -> Bool {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        var buffers: [IOSurface] = []
        for _ in 0 ..< Self.bufferCount {
            guard
                let buffer = IOSurface(properties: [
                    .width: width, .height: height, .bytesPerElement: 4, .pixelFormat: Self.pixelFormat
                ])
            else { return false }
            if let colorSpace, let list = colorSpace.copyPropertyList() {
                IOSurfaceSetValue(buffer, kIOSurfaceColorSpace, list)
            }
            buffers.append(buffer)
        }
        state.buffers = buffers
        state.size = (width, height)
        state.shown = nil
        // A new buffer has none of the frame yet: all of it is missing.
        state.missing = [ClosedRange<Int>?](repeating: 0 ... height - 1, count: Self.bufferCount)
        return true
    }

    private func copy(_ surface: Surface, rows: ClosedRange<Int>, into buffer: IOSurface) {
        let rows = max(rows.lowerBound, 0) ... min(rows.upperBound, surface.height - 1)
        buffer.lock(options: [], seed: nil)
        defer { buffer.unlock(options: [], seed: nil) }
        let stride = buffer.bytesPerRow
        let rowBytes = surface.width * 4
        surface.pixels.withUnsafeBytes { source in
            guard let start = source.baseAddress else { return }
            for row in rows {
                (buffer.baseAddress + row * stride).copyMemory(from: start + row * rowBytes, byteCount: rowBytes)
            }
        }
    }
}
