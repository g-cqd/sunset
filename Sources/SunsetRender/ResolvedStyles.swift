/// The styles of the frame being drawn, resolved on first use (`ResolvedStyle`), by style id. An entry is good for the frame that made it only (`stamp`): the
/// palette, reverse video, the blink phase or the screen's style ids (it compacts its table) may change between frames, and stamping is cheaper than clearing.
struct ResolvedStyles {
    private struct Entry {
        var stamp: UInt32
        var style: ResolvedStyle
    }

    private var entries: ContiguousArray<Entry> = []
    private var stamp: UInt32 = 0

    /// A new frame: every entry is out of date.
    mutating func startFrame() {
        stamp &+= 1
        if stamp == 0 {
            for index in entries.indices { entries[index].stamp = 0 }
            stamp = 1
        }
    }

    /// The style, resolved for this frame. The lookup is inlined into the walk; resolving (once a frame a style) is not.
    @inline(__always) mutating func style(_ id: UInt16, in frame: CPURenderer.Frame) -> ResolvedStyle {
        let index = Int(id)
        if index < entries.count, entries[index].stamp == stamp { return entries[index].style }
        return resolve(index, in: frame)
    }

    @inline(never) private mutating func resolve(_ index: Int, in frame: CPURenderer.Frame) -> ResolvedStyle {
        let resolved = ResolvedStyle(frame.styles[index], frame: frame)
        if index >= entries.count {
            entries.append(
                contentsOf: repeatElement(Entry(stamp: 0, style: resolved), count: index + 1 - entries.count)
            )
        }
        entries[index] = Entry(stamp: stamp, style: resolved)
        return resolved
    }
}
