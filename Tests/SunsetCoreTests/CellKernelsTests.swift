import Testing

@testable import SunsetCore

@Suite("Cell kernels: used length") struct CellKernelsTests {
    private func lengths(_ cells: [Cell]) -> (vector: Int, scalar: Int) {
        cells.withUnsafeBufferPointer { (CellKernels.usedLength($0), CellKernels.usedLengthScalar($0)) }
    }

    @Test func `the length is up to the last non-empty cell, for every length, position and alignment`() {
        for count in 0 ... 70 {
            for last in -1 ..< count {
                var cells = [Cell](repeating: .empty, count: count)
                if last >= 0 { cells[last] = Cell(scalar: 0x41, width: .narrow, style: 0) }
                // Something non-empty before it must not matter.
                if last > 2 { cells[1] = Cell(scalar: 0x42, width: .narrow, style: 0) }
                let (vector, scalar) = lengths(cells)
                #expect(scalar == last + 1, "scalar: count \(count) last \(last)")
                #expect(vector == last + 1, "vector: count \(count) last \(last)")
            }
        }
    }

    @Test func `a blank with a style, a wide spacer and a high bit all count as content`() {
        let cases: [Cell] = [
            Cell(scalar: 0, width: .narrow, style: 3),
            Cell(scalar: 0, width: .spacerTail, style: 0),
            Cell(raw: 1 << 63)
        ]
        for content in cases {
            var cells = [Cell](repeating: .empty, count: 40)
            cells[17] = content
            let (vector, scalar) = lengths(cells)
            #expect(vector == 18 && scalar == 18)
        }
    }
}
