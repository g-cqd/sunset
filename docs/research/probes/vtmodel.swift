// Probe T0.4: a headless VT model in Swift, to measure parse-to-cells cost on vtebench-like streams.
// NOT shipped code. Subset only: print (ASCII + UTF-8), C0 (LF CR BS HT), CSI (cursor moves, CUP, ED/EL, SGR, DECSTBM, modes ignored).
// Row indirection (logical row -> physical slot), 8-byte cells, page-less, global style table (u16 ids). Unsafe pointers throughout (probe only).
import Foundation

@inline(__always) func nowNs() -> UInt64 { clock_gettime_nsec_np(CLOCK_UPTIME_RAW) }

struct Style: Hashable { var fg: UInt32 = 0, bg: UInt32 = 0, attrs: UInt8 = 0 }

final class Model {
    let cols: Int, rows: Int
    let cells: UnsafeMutablePointer<UInt64>  // rows * cols, physical slots
    var rowMap: UnsafeMutablePointer<Int32>  // logical -> physical
    let dirty: UnsafeMutablePointer<UInt8>  // per physical slot
    var cx = 0, cy = 0, pendingWrap = false
    var top = 0, bottom: Int  // scroll region (inclusive)
    var style: Style = Style(), styleId: UInt64 = 0
    var styles: [Style: UInt16] = [Style(): 0]
    var styleCount = 1
    var scrolls = 0
    // parser state
    var state = 0  // 0 ground, 1 esc, 2 csi, 3 other string (skip to ST/BEL), 4 esc-in-string
    var params = [Int](repeating: 0, count: 16)
    var nparams = 0
    var cur = -1
    var csiPrivate = false
    var pend: [UInt8] = []
    var utf8Need = 0, utf8Acc: UInt32 = 0

    init(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
        bottom = rows - 1
        cells = .allocate(capacity: rows * cols)
        cells.initialize(repeating: 0, count: rows * cols)
        rowMap = .allocate(capacity: rows)
        for i in 0 ..< rows { rowMap[i] = Int32(i) }
        dirty = .allocate(capacity: rows)
        dirty.initialize(repeating: 0, count: rows)
    }
    deinit {
        cells.deallocate()
        rowMap.deallocate()
        dirty.deallocate()
    }

    @inline(__always) func rowPtr(_ y: Int) -> UnsafeMutablePointer<UInt64> { cells + Int(rowMap[y]) * cols }

    func lookupStyle() {
        if let id = styles[style] {
            styleId = UInt64(id) << 24
            return
        }
        let id = UInt16(truncatingIfNeeded: styleCount)
        styleCount += 1
        styles[style] = id
        styleId = UInt64(id) << 24
    }

    @inline(__always) func clearRow(_ y: Int) {
        let p = rowPtr(y)
        p.update(repeating: 0, count: cols)
        dirty[Int(rowMap[y])] = 1
    }

    func scrollUp() {  // LF at bottom of region: rotate row map, clear the freed row
        scrolls += 1
        let first = rowMap[top]
        if bottom > top { (rowMap + top).update(from: rowMap + top + 1, count: bottom - top) }
        rowMap[bottom] = first
        clearRow(bottom)
    }
    @inline(__always) func linefeed() { if cy == bottom { scrollUp() } else if cy < rows - 1 { cy += 1 } }

    @inline(__always) func put(_ cp: UInt32, width: Int) {
        if pendingWrap || cx + width > cols {
            cx = 0
            linefeed()
            pendingWrap = false
        }
        let p = rowPtr(cy)
        let c = UInt64(cp) << 2 | styleId
        if width == 2 {
            p[cx] = c | (1 << 40)
            p[cx + 1] = (2 << 40) | styleId
            cx += 2
        } else {
            p[cx] = c
            cx += 1
        }
        dirty[Int(rowMap[cy])] = 1
        if cx >= cols {
            cx = cols - 1
            pendingWrap = true
        }
    }

    @inline(__always) static func width(_ cp: UInt32) -> Int {
        if cp < 0x300 { return 1 }
        if cp >= 0x300 && cp <= 0x36F { return 0 }
        if (cp >= 0x1100 && cp <= 0x115F) || (cp >= 0x2E80 && cp <= 0xA4CF) || (cp >= 0xAC00 && cp <= 0xD7A3)
            || (cp >= 0xF900 && cp <= 0xFAFF)
            || (cp >= 0xFE30 && cp <= 0xFE6F) || (cp >= 0xFF00 && cp <= 0xFF60) || (cp >= 0xFFE0 && cp <= 0xFFE6)
            || (cp >= 0x1F300 && cp <= 0x1F64F)
            || (cp >= 0x1F900 && cp <= 0x1F9FF) || (cp >= 0x20000 && cp <= 0x3FFFD)
        {
            return 2
        }
        return 1
    }

    // ---- CSI -----
    @inline(__always) func param(_ i: Int, _ d: Int) -> Int { i < nparams && params[i] > 0 ? params[i] : d }
    func csiDispatch(_ f: UInt8) {
        switch f {
            case UInt8(ascii: "H"), UInt8(ascii: "f"):
                cy = min(rows - 1, param(0, 1) - 1)
                cx = min(cols - 1, param(1, 1) - 1)
                pendingWrap = false
            case UInt8(ascii: "A"):
                cy = max(top, cy - param(0, 1))
                pendingWrap = false
            case UInt8(ascii: "B"):
                cy = min(bottom, cy + param(0, 1))
                pendingWrap = false
            case UInt8(ascii: "C"):
                cx = min(cols - 1, cx + param(0, 1))
                pendingWrap = false
            case UInt8(ascii: "D"):
                cx = max(0, cx - param(0, 1))
                pendingWrap = false
            case UInt8(ascii: "J"):
                let m = nparams > 0 ? params[0] : 0
                if m == 2 || m == 3 {
                    for y in 0 ..< rows { clearRow(y) }
                } else if m == 0 {
                    rowPtr(cy).advanced(by: cx).update(repeating: 0, count: cols - cx)
                    if cy + 1 < rows { for y in (cy + 1) ..< rows { clearRow(y) } }
                } else {
                    rowPtr(cy).update(repeating: 0, count: cx + 1)
                    for y in 0 ..< cy { clearRow(y) }
                }
            case UInt8(ascii: "K"):
                let m = nparams > 0 ? params[0] : 0
                let p = rowPtr(cy)
                if m == 0 {
                    (p + cx).update(repeating: 0, count: cols - cx)
                } else if m == 1 {
                    p.update(repeating: 0, count: cx + 1)
                } else {
                    p.update(repeating: 0, count: cols)
                }
                dirty[Int(rowMap[cy])] = 1
            case UInt8(ascii: "r"):
                if csiPrivate { break }
                let t = param(0, 1) - 1
                let b = param(1, rows) - 1
                if t < b && b < rows {
                    top = t
                    bottom = b
                    cx = 0
                    cy = 0
                }
            case UInt8(ascii: "m"): sgr()
            default: break  // modes (h/l), DSR etc.: ignored by the probe
        }
    }
    func sgr() {
        if nparams == 0 {
            style = Style()
            lookupStyle()
            return
        }
        var i = 0
        while i < nparams {
            let p = max(0, params[i])
            switch p {
                case 0: style = Style()
                case 1: style.attrs |= 1
                case 3: style.attrs |= 2
                case 4: style.attrs |= 4
                case 22: style.attrs &= ~1
                case 23: style.attrs &= ~2
                case 24: style.attrs &= ~4
                case 30 ... 37: style.fg = UInt32(p - 30) | 0x0100_0000
                case 40 ... 47: style.bg = UInt32(p - 40) | 0x0100_0000
                case 90 ... 97: style.fg = UInt32(p - 90 + 8) | 0x0100_0000
                case 100 ... 107: style.bg = UInt32(p - 100 + 8) | 0x0100_0000
                case 39: style.fg = 0
                case 49: style.bg = 0
                case 38, 48:
                    var v: UInt32 = 0
                    if i + 1 < nparams, params[i + 1] == 5, i + 2 < nparams {
                        v = UInt32(params[i + 2] & 0xFF) | 0x0100_0000
                        i += 2
                    } else if i + 1 < nparams, params[i + 1] == 2, i + 4 < nparams {
                        v =
                            (UInt32(params[i + 2] & 0xFF) << 16 | UInt32(params[i + 3] & 0xFF) << 8
                                | UInt32(params[i + 4] & 0xFF)) | 0x0200_0000
                        i += 4
                    }
                    if p == 38 { style.fg = v } else { style.bg = v }
                default: break
            }
            i += 1
        }
        lookupStyle()
    }

    // ---- stream -----
    /// useSIMD: skip ahead over printable ASCII runs 16 bytes at a time.
    func feed(_ buf: UnsafeBufferPointer<UInt8>, useRunFastPath: Bool, mode: Int = 1) {
        var i = 0
        let n = buf.count
        // swift-format-ignore: NeverForceUnwrap
        let base = buf.baseAddress!
        while i < n {
            switch state {
                case 0:
                    let b = base[i]
                    if b >= 0x20 && b < 0x7F {  // printable ASCII run
                        var j = i + 1
                        if useRunFastPath {
                            if mode == 2 {  // umax trick: (v - 0x20) >= 0x5F  <=>  v < 0x20 || v >= 0x7F
                                while j + 16 <= n {
                                    let v = UnsafeRawPointer(base + j).loadUnaligned(as: SIMD16<UInt8>.self)
                                    if (v &- 0x20).max() >= 0x5F { break }
                                    j += 16
                                }
                            } else if mode == 3 {  // hybrid: 16 scalar bytes first, then umax SIMD
                                let lim = min(n, j + 16)
                                while j < lim {
                                    let c = base[j]
                                    if c < 0x20 || c >= 0x7F { break }
                                    j += 1
                                }
                                if j == lim {
                                    while j + 16 <= n {
                                        let v = UnsafeRawPointer(base + j).loadUnaligned(as: SIMD16<UInt8>.self)
                                        if (v &- 0x20).max() >= 0x5F { break }
                                        j += 16
                                    }
                                }
                            } else {
                                while j + 16 <= n {
                                    let v = UnsafeRawPointer(base + j).loadUnaligned(as: SIMD16<UInt8>.self)
                                    if any((v .< 0x20) .| (v .>= 0x7F)) { break }
                                    j += 16
                                }
                            }
                        }
                        while j < n {
                            let c = base[j]
                            if c < 0x20 || c >= 0x7F { break }
                            j += 1
                        }
                        // write the run [i, j) into cells, wrapping as needed
                        var k = i
                        while k < j {
                            if pendingWrap || cx >= cols {
                                cx = 0
                                linefeed()
                                pendingWrap = false
                            }
                            let take = min(j - k, cols - cx)
                            let p = rowPtr(cy) + cx
                            var t = 0
                            while t < take {
                                p[t] = UInt64(base[k + t]) << 2 | styleId
                                t += 1
                            }
                            dirty[Int(rowMap[cy])] = 1
                            cx += take
                            k += take
                            if cx >= cols {
                                cx = cols - 1
                                pendingWrap = true
                            }
                        }
                        i = j
                    } else if b < 0x20 {
                        switch b {
                            case 0x0A, 0x0B, 0x0C:
                                linefeed()
                                pendingWrap = false
                            case 0x0D:
                                cx = 0
                                pendingWrap = false
                            case 0x08:
                                if cx > 0 { cx -= 1 }
                                pendingWrap = false
                            case 0x09:
                                cx = min(cols - 1, (cx / 8 + 1) * 8)
                                pendingWrap = false
                            case 0x1B: state = 1
                            default: break
                        }
                        i += 1
                    } else if b >= 0x80 {  // UTF-8 (probe: decode inline, no split handling across chunks beyond pend)
                        var cp: UInt32 = 0
                        var len = 0
                        if b >= 0xF0 {
                            len = 4
                            cp = UInt32(b & 0x07)
                        } else if b >= 0xE0 {
                            len = 3
                            cp = UInt32(b & 0x0F)
                        } else if b >= 0xC0 {
                            len = 2
                            cp = UInt32(b & 0x1F)
                        } else {
                            i += 1
                            continue
                        }
                        if i + len > n {
                            i = n
                            continue
                        }  // truncated at chunk end: dropped by the probe (streams are chunked on 64 KiB)
                        for q in 1 ..< len { cp = cp << 6 | UInt32(base[i + q] & 0x3F) }
                        let w = Model.width(cp)
                        if w > 0 { put(cp, width: w) }
                        i += len
                    } else {
                        i += 1
                    }  // DEL
                case 1:
                    let b = base[i]
                    i += 1
                    if b == UInt8(ascii: "[") {
                        state = 2
                        nparams = 0
                        cur = -1
                        csiPrivate = false
                    } else if b == UInt8(ascii: "]") || b == UInt8(ascii: "P") || b == UInt8(ascii: "_")
                        || b == UInt8(ascii: "^") || b == UInt8(ascii: "X")
                    {
                        state = 3
                    } else {
                        state = 0
                    }
                case 2:
                    let b = base[i]
                    i += 1
                    if b >= 0x30 && b <= 0x39 {
                        cur = (cur < 0 ? 0 : cur) * 10 + Int(b - 0x30)
                    } else if b == UInt8(ascii: ";") || b == UInt8(ascii: ":") {
                        if nparams < 16 {
                            params[nparams] = max(cur, 0)
                            nparams += 1
                        }
                        cur = -1
                    } else if b == UInt8(ascii: "?") || b == UInt8(ascii: ">") || b == UInt8(ascii: "=")
                        || b == UInt8(ascii: "<")
                    {
                        csiPrivate = true
                    } else if b >= 0x40 && b <= 0x7E {
                        if cur >= 0 || nparams > 0 {
                            if nparams < 16 {
                                params[nparams] = max(cur, 0)
                                nparams += 1
                            }
                        }
                        csiDispatch(b)
                        state = 0
                    } else if b < 0x20 {
                        // C0 inside CSI: ignore
                        if b == 0x1B { state = 1 }
                    }
                case 3:
                    let b = base[i]
                    i += 1
                    if b == 0x07 { state = 0 } else if b == 0x1B { state = 4 }
                default:
                    state = base[i] == UInt8(ascii: "\\") ? 0 : 3
                    i += 1
            }
        }
    }

    func checksum() -> UInt64 {
        var h: UInt64 = 1_469_598_103_934_665_603
        for y in 0 ..< rows {
            let p = rowPtr(y)
            for x in 0 ..< cols { h = (h ^ p[x]) &* 1_099_511_628_211 }
        }
        return h ^ UInt64(cx) << 8 ^ UInt64(cy) << 16 ^ UInt64(scrolls) << 24
    }
    func rowText(_ y: Int) -> String {
        var s = ""
        let p = rowPtr(y)
        for x in 0 ..< cols {
            let c = UInt32((p[x] >> 2) & 0x1FFFFF)
            s.unicodeScalars.append(c == 0 ? " " : Unicode.Scalar(c) ?? "?")
        }
        return s.trimmingCharacters(in: .whitespaces)
    }
}

func runChunked(_ m: Model, _ data: [UInt8], chunk: Int, fast: Bool, mode: Int = 1) {
    data.withUnsafeBufferPointer { bp in
        var off = 0
        while off < bp.count {
            let e = min(bp.count, off + chunk)
            m.feed(UnsafeBufferPointer(rebasing: bp[off ..< e]), useRunFastPath: fast, mode: mode)
            off = e
        }
    }
}

// ---- correctness: hand tests + differential (fast path vs plain loop) ----
do {
    let m = Model(cols: 10, rows: 3)
    let t = Array("ab\r\ncd\u{1B}[1;31mX\u{1B}[0mY\r\nlast\nmore\n".utf8)
    runChunked(m, t, chunk: 4, fast: true)
    // rows after: "cdXY" scrolled... print state
    precondition(
        m.rowText(0) == "last" && m.rowText(1) == "more" && m.rowText(2) == "",
        "hand test failed: \(m.rowText(0))|\(m.rowText(1))|\(m.rowText(2))"
    )
    let m2 = Model(cols: 4, rows: 2)
    runChunked(m2, Array("abcdefghij".utf8), chunk: 3, fast: false)
    precondition(
        m2.rowText(0) == "efgh" && m2.rowText(1) == "ij",
        "wrap test failed: \(m2.rowText(0))|\(m2.rowText(1))"
    )
}
let names = ["scrolling", "scrolling_fullscreen", "scrolling_top_region", "dense_cells", "medium_cells", "unicode"]
print(
    "Swift VT model probe (120x40, 8-byte cells, row indirection); chunk = 64 KiB; ms per MiB of input, best of 15 passes; lower is better"
)
print("variants: scalar | simd16 any(mask) | simd16 umax | hybrid (16 scalar, then umax)")
for name in names {
    // swift-format-ignore: NeverUseForceTry
    let data = [UInt8](try! Data(contentsOf: URL(fileURLWithPath: "/tmp/probe/vtstreams/\(name).bin")))
    var best = [Double](repeating: .infinity, count: 4)
    var sums = [UInt64](repeating: 0, count: 4)
    let variants: [(Bool, Int)] = [(false, 1), (true, 1), (true, 2), (true, 3)]
    for (vi, v) in variants.enumerated() {
        for _ in 0 ..< 15 {
            let m = Model(cols: 120, rows: 40)
            let t0 = nowNs()
            runChunked(m, data, chunk: 65536, fast: v.0, mode: v.1)
            let dt = Double(nowNs() - t0) / 1e6
            best[vi] = min(best[vi], dt * 1_048_576 / Double(data.count))
            sums[vi] = m.checksum()
        }
    }
    let same = sums.allSatisfy { $0 == sums[0] }
    print(
        String(
            format: "%-24@ %8.2f %8.2f %8.2f %8.2f   %@",
            name as NSString,
            best[0],
            best[1],
            best[2],
            best[3],
            (same ? "same screen" : "DIFFERENT") as NSString
        )
    )
}
