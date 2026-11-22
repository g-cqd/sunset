import AemiKernel
import Testing

@testable import SunsetCore

/// Images sent compressed (`o=z`, zlib), as `kitten icat` sends every picture it converts (roadmap 0010 D, ADR-0117): read
/// through the host's inflater, never past the size the image must have (raw pixels) or the quota (a PNG); refused as kitty
/// refuses when there is no inflater or the data does not inflate.
@Suite("kitty graphics: compressed images") struct KittyCompressionTests {
    /// An inflater that only knows `table`'s inputs, and records the limits it is given.
    private final class Stub: Inflater, @unchecked Sendable {
        let table: [[UInt8]: [UInt8]]
        var limits: [Int] = []

        init(_ table: [[UInt8]: [UInt8]]) {
            self.table = table
        }

        func inflate(_ data: [UInt8], limit: Int) -> [UInt8]? {
            limits.append(limit)
            guard let out = table[data], out.count <= limit else { return nil }
            return out
        }
    }

    private let packed: [UInt8] = [1, 2, 3]
    private let pixels: [UInt8] = [10, 20, 30, 40, 50, 60]

    private func terminal(_ inflater: (any Inflater)?) -> Terminal {
        var t = Terminal(columns: 20, rows: 6)
        t.setCellPixelSize(width: 10, height: 20)
        if let inflater { t.setInflater(inflater) }
        return t
    }

    private func send(_ t: inout Terminal, _ control: String, _ data: [UInt8]) -> String {
        t.feed("\(esc)_G\(control);\(Base64.encodedString(data))\(esc)\\")
        return String(decoding: t.takeReplies(), as: UTF8.self)
    }

    @Test func `inflated to the size its pixels must have, then kept as sent uncompressed`() {
        let stub = Stub([packed: pixels])
        var t = terminal(stub)
        #expect(send(&t, "a=t,i=7,f=24,s=2,v=1,o=z", packed) == "\(esc)_Gi=7;OK\(esc)\\")
        #expect(t.screen.graphics.images[7]?.pixels == pixels)
        #expect(stub.limits == [6], "never more than 2 × 1 × 3 bytes")
    }

    @Test func `refused without an inflater, when it does not inflate, or when it inflates short`() {
        var without = terminal(nil)
        #expect(send(&without, "a=t,i=7,f=24,s=2,v=1,o=z", packed).hasPrefix("\(esc)_Gi=7;EINVAL"))
        var t = terminal(Stub([packed: pixels, [9]: [1, 2]]))
        #expect(send(&t, "a=t,i=7,f=24,s=2,v=1,o=z", [4, 4]).hasPrefix("\(esc)_Gi=7;EINVAL"))
        #expect(send(&t, "a=t,i=8,f=24,s=2,v=1,o=z", [9]).hasPrefix("\(esc)_Gi=8;ENODATA"))
        #expect(t.screen.graphics.images.isEmpty)
    }

    @Test func `a size past the quota is refused before inflating; a PNG is inflated within the quota`() {
        let stub = Stub([:])
        var t = terminal(stub)
        t.setGraphicsQuota(bytes: 1_000)
        #expect(send(&t, "a=t,i=7,f=32,s=100,v=100,o=z", packed).hasPrefix("\(esc)_Gi=7;ENOSPC"))
        #expect(stub.limits.isEmpty)
        _ = send(&t, "a=t,i=8,f=100,o=z", packed)
        #expect(stub.limits == [1_000])
    }

    @Test func `the inflater stays through a full reset`() {
        let stub = Stub([packed: pixels])
        var t = terminal(stub)
        t.feed("\(esc)c")
        #expect(send(&t, "a=t,i=7,f=24,s=2,v=1,o=z", packed) == "\(esc)_Gi=7;OK\(esc)\\")
    }
}
