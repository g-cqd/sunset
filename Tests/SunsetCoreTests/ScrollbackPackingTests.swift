import Testing

@testable import SunsetCore

@Suite("Scrollback packing") struct ScrollbackPackingTests {
    private let codec = WordRunCodec()

    /// A line of `columns` equal cells whose scalar says which line it is (compressible by `WordRunCodec`).
    private func line(_ value: UInt32, columns: Int = 40) -> ArraySlice<Cell> {
        ArraySlice((0 ..< columns).map { _ in Cell(scalar: value, width: .narrow, style: UInt16(value % 5)) })
    }

    private func filled(lines: Int, limit: Int, columns: Int = 40) -> Scrollback {
        var history = Scrollback(columns: columns, limit: limit)
        for index in 0 ..< lines { history.push(line(UInt32(index + 1), columns: columns), wrapped: index % 4 == 0) }
        return history
    }

    private func same(_ a: Scrollback, _ b: Scrollback) -> Bool {
        guard a.count == b.count else { return false }
        for index in 0 ..< a.count {
            if a.isWrapped(index) != b.isWrapped(index) { return false }
            for column in [0, 1, 39, 40] where a[index, column] != b[index, column] { return false }
        }
        return true
    }

    @Test func `packed lines read back exactly, the wrapped marks included`() {
        let original = filled(lines: 1000, limit: 1000)
        var packed = original
        let chunks = packed.pack(using: codec, keepingRecent: 2)
        #expect(chunks > 0)
        #expect(same(original, packed))
    }

    @Test func `the newest chunks and a chunk that is not full stay as they are`() {
        var history = filled(lines: 128 * 5 + 40, limit: 10_000)
        history.pack(using: codec, keepingRecent: 2)
        // Six chunks (five full, one partly filled); the two newest stay, so three are packed.
        #expect(history.packedChunks == 3)
        history.pack(using: codec, keepingRecent: 0)
        #expect(history.packedChunks == 5, "the chunk still being filled is never packed")
    }

    @Test func `packing again does nothing more, and says how many chunks it packed`() {
        var history = filled(lines: 128 * 6, limit: 10_000)
        #expect(history.pack(using: codec, keepingRecent: 1) == 5)
        #expect(history.pack(using: codec, keepingRecent: 1) == 0)
    }

    @Test func `a limit stops packing after that many chunks, and the rest is packed by the next call`() {
        var history = filled(lines: 128 * 10, limit: 10_000)
        #expect(history.pack(using: codec, keepingRecent: 1, limit: 3) == 3)
        #expect(history.packedChunks == 3)
        #expect(history.pack(using: codec, keepingRecent: 1, limit: 3) == 3)
        #expect(history.pack(using: codec, keepingRecent: 1, limit: 100) == 3)
        #expect(history.packedChunks == 9)
    }

    @Test func `packing takes the cells out of memory and keeps far fewer bytes`() {
        var history = filled(lines: 128 * 8, limit: 10_000)
        let before = history.storedCells
        history.pack(using: codec, keepingRecent: 1)
        #expect(history.storedCells <= before / 8 + 128 * 40)
        #expect(history.packedBytes > 0 && history.packedBytes < before * 8 / 10)
    }

    @Test func `a chunk the codec cannot make smaller stays as cells`() {
        var history = filled(lines: 128 * 4, limit: 10_000)
        #expect(history.pack(using: NoGainCodec(), keepingRecent: 0) == 0)
        #expect(history.packedChunks == 0 && history.packedBytes == 0)
    }

    @Test func `lines can still be added, and the oldest packed ones leave when the history is full`() {
        var history = filled(lines: 128 * 4, limit: 300)
        history.pack(using: codec, keepingRecent: 1)
        for index in 0 ..< 600 { history.push(line(UInt32(10_000 + index)), wrapped: false) }
        #expect(history.count == 300)
        #expect(history[299, 0].scalar == 10_599 && history[0, 0].scalar == 10_300)
        #expect(history.packedChunks == 0, "everything that was packed has left")
        history.pack(using: codec, keepingRecent: 1)
        #expect(history.packedChunks >= 1 && history[0, 0].scalar == 10_300 && history[299, 0].scalar == 10_599)
    }

    @Test func `a copy taken before packing is not changed by it, and one taken after shares the packed chunks`() {
        let original = filled(lines: 1000, limit: 1000)
        var packed = original
        packed.pack(using: codec, keepingRecent: 1)
        let copy = packed
        #expect(original.packedChunks == 0 && same(original, packed) && same(copy, packed))
        #expect(copy.packedChunks == packed.packedChunks)
    }

    @Test func `style rewriting reaches the packed lines too`() {
        var plain = filled(lines: 800, limit: 800)
        var packed = plain
        packed.pack(using: codec, keepingRecent: 1)
        plain.mapStyles { $0 + 10 }
        packed.mapStyles { $0 + 10 }
        #expect(same(plain, packed))
        #expect(packed[0, 0].styleID == plain[0, 0].styleID && packed[0, 0].styleID >= 10)
    }

    @Test func `dropping what was decoded changes nothing that is read`() {
        let original = filled(lines: 1000, limit: 1000)
        var packed = original
        packed.pack(using: codec, keepingRecent: 1)
        #expect(same(original, packed))
        packed.releaseDecoded()
        #expect(same(original, packed))
    }

    @Test func `a codec that cannot unpack gives blank cells, not a crash`() {
        var history = filled(lines: 128 * 3, limit: 1000)
        history.pack(using: BrokenCodec(), keepingRecent: 0)
        #expect(history[0, 0] == .empty && history.count == 128 * 3 - 0)
    }

    @Test func `clearing a packed history empties it`() {
        var history = filled(lines: 800, limit: 800)
        history.pack(using: codec, keepingRecent: 1)
        history.removeAll()
        #expect(history.count == 0 && history.packedChunks == 0 && history.packedBytes == 0)
        history.push(line(5), wrapped: false)
        #expect(history[0, 0].scalar == 5)
    }

    @Test func `many tasks reading packed lines at once all see the same lines`() async {
        var history = filled(lines: 128 * 6, limit: 10_000)
        history.pack(using: codec, keepingRecent: 1)
        let shared = history
        let sums = await withTaskGroup(of: UInt64.self) { group in
            for _ in 0 ..< 8 {
                group.addTask {
                    var sum: UInt64 = 0
                    for index in 0 ..< shared.count { sum &+= UInt64(shared[index, 3].scalar) }
                    return sum
                }
            }
            var all: [UInt64] = []
            for await sum in group { all.append(sum) }
            return all
        }
        let expected = (1 ... UInt64(128 * 6)).reduce(0, +)
        #expect(sums.allSatisfy { $0 == expected })
    }
}
