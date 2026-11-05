// Probe T0.2 (sunset roadmap 0002, ADR-0013): bytes per cell of cold history on a real-text corpus.
// Feeds a byte stream through the VT model (120x40, 8-byte cells, 1,000-row hot ring) and, for every row that leaves the hot ring, compares:
//   raw        : 960 bytes per row (120 cells x 8)
//   LZ4_RAW / LZFSE / ZLIB of raw rows, compressed in 1 MiB pages the way a page-compressing terminal does (the platform's libcompression)
//   structural : the model's own encoding (trimmed UTF-8 text + style runs), alone and then compressed in 1 MiB pieces with LZ4_RAW / ZLIB
// Sizes are deterministic (no timing here). Usage: ColdHistoryProbe <stream file> [max MiB]
import Compression
import Foundation
import VTModel

let args = CommandLine.arguments
guard args.count >= 2, let data = FileManager.default.contents(atPath: args[1]) else { print("usage: ColdHistoryProbe <stream> [MiB]"); exit(2) }
let limit = args.count > 2 ? Int(args[2])! << 20 : data.count
let bytes = [UInt8](data.prefix(limit))
let screen = makeScreen(.c8, sb: 1000, cold: true)
let page = 1 << 20
var pageBuf = [UInt8](); pageBuf.reserveCapacity(page)
var rawRows = 0
var comp: [(String, compression_algorithm, Int)] = [("LZ4_RAW", COMPRESSION_LZ4_RAW, 0), ("LZFSE", COMPRESSION_LZFSE, 0), ("ZLIB", COMPRESSION_ZLIB, 0)]
let scratch = UnsafeMutablePointer<UInt8>.allocate(capacity: page * 2)
func flushPage() {
    guard !pageBuf.isEmpty else { return }
    pageBuf.withUnsafeBufferPointer { src in
        for i in 0..<comp.count { comp[i].2 += compression_encode_buffer(scratch, page * 2, src.baseAddress!, src.count, nil, comp[i].1) }
    }
    pageBuf.removeAll(keepingCapacity: true)
}
screen.setEvictSink { row in
    pageBuf.append(contentsOf: row); rawRows += 1
    if pageBuf.count >= page { flushPage() }
}
var off = 0
bytes.withUnsafeBufferPointer { bp in
    while off < bp.count { let e = min(bp.count, off + 65536); screen.feed(UnsafeBufferPointer(rebasing: bp[off..<e])); off = e }
}
flushPage()
let rows = screen.coldRows, cells = rows * 120
let cold = screen.coldData
var coldComp: [(String, compression_algorithm, Int)] = [("LZ4_RAW", COMPRESSION_LZ4_RAW, 0), ("ZLIB", COMPRESSION_ZLIB, 0)]
cold.withUnsafeBufferPointer { src in
    var o = 0
    while o < src.count { let e = min(src.count, o + page); for i in 0..<coldComp.count { coldComp[i].2 += compression_encode_buffer(scratch, page * 2, src.baseAddress! + o, e - o, nil, coldComp[i].1) }; o = e }
}
func line(_ name: String, _ b: Int) { print(String(format: "%-34@ %12d B  %7.3f B/cell  %6.2f B/row  %6.2f%% of raw", name as NSString, b, Double(b) / Double(cells), Double(b) / Double(rows), 100 * Double(b) / Double(rows * 960))) }
print("input \(bytes.count >> 20) MiB, evicted rows \(rows) (\(rawRows) sunk), cells \(cells)")
line("raw 8-byte cells", rows * 960)
for c in comp { line("raw rows + \(c.0) (1 MiB pages)", c.2) }
line("structural (text + style runs)", cold.count)
for c in coldComp { line("structural + \(c.0) (1 MiB pieces)", c.2) }
