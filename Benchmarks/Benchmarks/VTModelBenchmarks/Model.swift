// Research code (sunset roadmap 0002, probes T0.1 and T0.4b): generic cell width (8/16/32 B), hot scrollback ring with zero-copy slot reuse, cold structural encoder for evicted rows.
// NOT shipped code; unsafe pointers throughout.
import Foundation

@inline(__always) func nowNs() -> UInt64 { clock_gettime_nsec_np(CLOCK_UPTIME_RAW) }
struct Style: Hashable { var fg: UInt32 = 0, bg: UInt32 = 0, attrs: UInt8 = 0 }


protocol CellType {
    static var zero: Self { get }
    static var inlineStyle: Bool { get }
    init(cp: UInt32, wide: UInt8, style: Style, id: UInt64)
    var cpValue: UInt32 { get }
    var styleKey: UInt32 { get }
    var wideTag: UInt8 { get }
}
struct C8: CellType {                                   // Ghostty-like: tag/codepoint | wide | 16-bit page-local style id
    var v: UInt64
    static var zero: C8 { C8(v: 0) }
    static var inlineStyle: Bool { false }
    @inline(__always) init(v: UInt64) { self.v = v }
    @inline(__always) init(cp: UInt32, wide: UInt8, style: Style, id: UInt64) { v = UInt64(cp) << 2 | id | UInt64(wide) << 40 }
    var cpValue: UInt32 { UInt32((v >> 2) & 0x1FFFFF) }
    var styleKey: UInt32 { UInt32((v >> 24) & 0xFFFF) }
    var wideTag: UInt8 { UInt8((v >> 40) & 3) }
}
struct C16: CellType {                                  // TerminalKit PackedCell-like: 8 B grapheme | length/width/32-bit style id
    var lo: UInt64, hi: UInt64
    static var zero: C16 { C16(lo: 0, hi: 0) }
    static var inlineStyle: Bool { false }
    @inline(__always) init(lo: UInt64, hi: UInt64) { self.lo = lo; self.hi = hi }
    @inline(__always) init(cp: UInt32, wide: UInt8, style: Style, id: UInt64) { lo = UInt64(cp); hi = id | UInt64(wide) << 8 | 1 << 16 }
    var cpValue: UInt32 { UInt32(truncatingIfNeeded: lo) }
    var styleKey: UInt32 { UInt32(truncatingIfNeeded: hi >> 24) }
    var wideTag: UInt8 { UInt8((hi >> 8) & 3) }
}
struct C32: CellType {                                  // kitty-like: colours inline (no style table), 32 bytes
    var a: UInt64, b: UInt64, c: UInt64, d: UInt64
    static var zero: C32 { C32(a: 0, b: 0, c: 0, d: 0) }
    static var inlineStyle: Bool { true }
    @inline(__always) init(a: UInt64, b: UInt64, c: UInt64, d: UInt64) { self.a = a; self.b = b; self.c = c; self.d = d }
    @inline(__always) init(cp: UInt32, wide: UInt8, style: Style, id: UInt64) { a = UInt64(cp) | UInt64(wide) << 32; b = UInt64(style.fg) | UInt64(style.bg) << 32; c = UInt64(style.attrs); d = 0 }
    var cpValue: UInt32 { UInt32(truncatingIfNeeded: a) }
    var styleKey: UInt32 { UInt32(truncatingIfNeeded: b) &* 31 &+ UInt32(truncatingIfNeeded: b >> 32) &* 17 &+ UInt32(truncatingIfNeeded: c) }
    var wideTag: UInt8 { UInt8((a >> 32) & 3) }
}

final class Model<C: CellType> {
    let cols: Int, rows: Int, sbCap: Int
    let cells: UnsafeMutablePointer<C>                  // (rows + sbCap) physical rows
    var rowMap: UnsafeMutablePointer<Int32>
    var freshNext: Int                                  // next never-used physical slot
    var sbRing: UnsafeMutablePointer<Int32>; var sbHead = 0, sbCount = 0
    var cx = 0, cy = 0, pendingWrap = false, top = 0, bottom: Int
    var style = Style(), styleId: UInt64 = 0
    var styles: [Style: UInt16] = [Style(): 0]; var styleCount = 1
    var cold = [UInt8](); var coldRows = 0; let coldOn: Bool
    var state = 0; var params = [Int](repeating: 0, count: 16); var nparams = 0; var cur = -1; var csiPrivate = false

    init(cols: Int, rows: Int, sbCap: Int, cold: Bool) {
        self.cols = cols; self.rows = rows; self.sbCap = sbCap; bottom = rows - 1; coldOn = cold
        cells = .allocate(capacity: (rows + sbCap) * cols)           // not initialised: pages untouched until used (mmap-backed by malloc for large sizes)
        for i in 0..<rows { (cells + i * cols).initialize(repeating: C.zero, count: cols) }
        rowMap = .allocate(capacity: rows); for i in 0..<rows { rowMap[i] = Int32(i) }
        freshNext = rows
        sbRing = .allocate(capacity: max(1, sbCap))
        if cold { self.cold.reserveCapacity(1 << 20) }
    }
    deinit { cells.deallocate(); rowMap.deallocate(); sbRing.deallocate() }
    @inline(__always) func rowPtr(_ y: Int) -> UnsafeMutablePointer<C> { cells + Int(rowMap[y]) * cols }
    // open-addressing style table (4096 slots, linear probing); key = fg<<32 | bg | attrs<<58 (fg,bg use <= 26 bits)
    var tKeys = [UInt64](repeating: .max, count: 4096); var tIds = [UInt16](repeating: 0, count: 4096); var lastKey: UInt64 = 0
    func lookupStyle() {
        if C.inlineStyle { return }
        let key = UInt64(style.fg) << 32 | UInt64(style.bg) | UInt64(style.attrs) << 58
        if key == lastKey { return }                                   // consecutive identical styles (common): no probe
        var h = Int((key &* 0x9E3779B97F4A7C15) >> 52)                 // 12 bits
        while true {
            let k = tKeys[h]
            if k == key { styleId = UInt64(tIds[h]) << 24; lastKey = key; return }
            if k == .max { break }
            h = (h + 1) & 4095
        }
        if styleCount >= 4096 { styleId = 0; return }
        tKeys[h] = key; tIds[h] = UInt16(truncatingIfNeeded: styleCount); styleCount += 1; styleId = UInt64(tIds[h]) << 24; lastKey = key
    }
    @inline(__always) func clearRow(_ y: Int) { rowPtr(y).update(repeating: C.zero, count: cols) }

    func encodeCold(_ p: UnsafeMutablePointer<C>) {      // structural: UTF-8 text (trailing blanks trimmed) + style runs
        var last = cols; while last > 0 && p[last - 1].cpValue == 0 { last -= 1 }
        let lenPos = cold.count; cold.append(0); cold.append(0)                       // u16 text length placeholder
        var runs: [(UInt32, UInt8)] = []; var prev: UInt32 = .max; var rl: UInt8 = 0
        var x = 0
        while x < last {
            let c = p[x]; let w = c.wideTag
            if w != 2 {                                                               // 2 = spacer
                let cp = c.cpValue == 0 ? 0x20 : c.cpValue
                if cp < 0x80 { cold.append(UInt8(cp)) }
                else if cp < 0x800 { cold.append(UInt8(0xC0 | cp >> 6)); cold.append(UInt8(0x80 | cp & 0x3F)) }
                else if cp < 0x10000 { cold.append(UInt8(0xE0 | cp >> 12)); cold.append(UInt8(0x80 | (cp >> 6) & 0x3F)); cold.append(UInt8(0x80 | cp & 0x3F)) }
                else { cold.append(UInt8(0xF0 | cp >> 18)); cold.append(UInt8(0x80 | (cp >> 12) & 0x3F)); cold.append(UInt8(0x80 | (cp >> 6) & 0x3F)); cold.append(UInt8(0x80 | cp & 0x3F)) }
            }
            let k = c.styleKey
            if k != prev || rl == 255 { if rl > 0 { runs.append((prev, rl)) }; prev = k; rl = 0 }
            rl += 1; x += 1
        }
        if rl > 0 { runs.append((prev, rl)) }
        let tl = cold.count - lenPos - 2; cold[lenPos] = UInt8(tl & 0xFF); cold[lenPos + 1] = UInt8(tl >> 8)
        cold.append(UInt8(min(runs.count, 255)))
        for r in runs.prefix(255) { cold.append(UInt8(r.0 & 0xFF)); cold.append(UInt8((r.0 >> 8) & 0xFF)); cold.append(r.1) }
        coldRows += 1
    }
    func scrollUp() {
        if top == 0 && bottom == rows - 1 && sbCap > 0 {                              // full-screen scroll: retire the top row into scrollback, zero copy
            let retired = rowMap[0]
            (rowMap).update(from: rowMap + 1, count: rows - 1)
            var slot: Int32
            if sbCount < sbCap && freshNext < rows + sbCap { slot = Int32(freshNext); freshNext += 1 }
            else {                                                                    // reuse the oldest hot scrollback row (encode it cold first)
                slot = sbRing[sbHead]; sbHead = (sbHead + 1) % sbCap; sbCount -= 1
                if coldOn { encodeCold(cells + Int(slot) * cols) }
            }
            sbRing[(sbHead + sbCount) % sbCap] = retired; sbCount += 1
            rowMap[rows - 1] = slot
            (cells + Int(slot) * cols).update(repeating: C.zero, count: cols)
        } else {
            let first = rowMap[top]
            if bottom > top { (rowMap + top).update(from: rowMap + top + 1, count: bottom - top) }
            rowMap[bottom] = first; clearRow(bottom)
        }
    }
    @inline(__always) func linefeed() { if cy == bottom { scrollUp() } else if cy < rows - 1 { cy += 1 } }
    @inline(__always) func put(_ cp: UInt32, width: Int) {
        if pendingWrap || cx + width > cols { cx = 0; linefeed(); pendingWrap = false }
        let p = rowPtr(cy)
        if width == 2 { p[cx] = C(cp: cp, wide: 1, style: style, id: styleId); p[cx + 1] = C(cp: 0, wide: 2, style: style, id: styleId); cx += 2 }
        else { p[cx] = C(cp: cp, wide: 0, style: style, id: styleId); cx += 1 }
        if cx >= cols { cx = cols - 1; pendingWrap = true }
    }
    static func width(_ cp: UInt32) -> Int {
        if cp < 0x300 { return 1 }; if cp <= 0x36F { return 0 }
        if (cp >= 0x1100 && cp <= 0x115F) || (cp >= 0x2E80 && cp <= 0xA4CF) || (cp >= 0xAC00 && cp <= 0xD7A3) || (cp >= 0xF900 && cp <= 0xFAFF) || (cp >= 0xFE30 && cp <= 0xFE6F) || (cp >= 0xFF00 && cp <= 0xFF60) || (cp >= 0xFFE0 && cp <= 0xFFE6) || (cp >= 0x1F300 && cp <= 0x1F64F) || (cp >= 0x1F900 && cp <= 0x1F9FF) || (cp >= 0x20000 && cp <= 0x3FFFD) { return 2 }
        return 1
    }
    @inline(__always) func param(_ i: Int, _ d: Int) -> Int { i < nparams && params[i] > 0 ? params[i] : d }
    func csiDispatch(_ f: UInt8) {
        switch f {
        case 72, 102: cy = min(rows - 1, param(0, 1) - 1); cx = min(cols - 1, param(1, 1) - 1); pendingWrap = false
        case 65: cy = max(top, cy - param(0, 1)); pendingWrap = false
        case 66: cy = min(bottom, cy + param(0, 1)); pendingWrap = false
        case 67: cx = min(cols - 1, cx + param(0, 1)); pendingWrap = false
        case 68: cx = max(0, cx - param(0, 1)); pendingWrap = false
        case 74: let m = nparams > 0 ? params[0] : 0
            if m == 2 || m == 3 { for y in 0..<rows { clearRow(y) } } else if m == 0 { (rowPtr(cy) + cx).update(repeating: C.zero, count: cols - cx); if cy + 1 < rows { for y in (cy + 1)..<rows { clearRow(y) } } } else { rowPtr(cy).update(repeating: C.zero, count: cx + 1); for y in 0..<cy { clearRow(y) } }
        case 75: let m = nparams > 0 ? params[0] : 0; let p = rowPtr(cy)
            if m == 0 { (p + cx).update(repeating: C.zero, count: cols - cx) } else if m == 1 { p.update(repeating: C.zero, count: cx + 1) } else { p.update(repeating: C.zero, count: cols) }
        case 114: if csiPrivate { break }; let t = param(0, 1) - 1, b = param(1, rows) - 1; if t < b && b < rows { top = t; bottom = b; cx = 0; cy = 0 }
        case 109: sgr()
        default: break
        }
    }
    func sgr() {
        if nparams == 0 { style = Style(); lastKey = .max - 1; lookupStyle(); return }
        var i = 0
        while i < nparams {
            let p = max(0, params[i])
            switch p {
            case 0: style = Style(); case 1: style.attrs |= 1; case 3: style.attrs |= 2; case 4: style.attrs |= 4
            case 22: style.attrs &= ~1; case 23: style.attrs &= ~2; case 24: style.attrs &= ~4
            case 30...37: style.fg = UInt32(p - 30) | 0x0100_0000
            case 40...47: style.bg = UInt32(p - 40) | 0x0100_0000
            case 90...97: style.fg = UInt32(p - 90 + 8) | 0x0100_0000
            case 100...107: style.bg = UInt32(p - 100 + 8) | 0x0100_0000
            case 39: style.fg = 0
            case 49: style.bg = 0
            case 38, 48:
                var v: UInt32 = 0
                if i + 1 < nparams, params[i + 1] == 5, i + 2 < nparams { v = UInt32(params[i + 2] & 0xFF) | 0x0100_0000; i += 2 }
                else if i + 1 < nparams, params[i + 1] == 2, i + 4 < nparams { v = (UInt32(params[i + 2] & 0xFF) << 16 | UInt32(params[i + 3] & 0xFF) << 8 | UInt32(params[i + 4] & 0xFF)) | 0x0200_0000; i += 4 }
                if p == 38 { style.fg = v } else { style.bg = v }
            default: break
            }
            i += 1
        }
        lookupStyle()
    }
    func feed(_ buf: UnsafeBufferPointer<UInt8>) {
        var i = 0; let n = buf.count; let base = buf.baseAddress!
        while i < n {
            switch state {
            case 0:
                let b = base[i]
                if b >= 0x20 && b < 0x7F {
                    var j = i + 1
                    let lim = min(n, j + 16)
                    while j < lim { let c = base[j]; if c < 0x20 || c >= 0x7F { break }; j += 1 }
                    if j == lim { while j + 16 <= n { let v = UnsafeRawPointer(base + j).loadUnaligned(as: SIMD16<UInt8>.self); if (v &- 0x20).max() >= 0x5F { break }; j += 16 }; while j < n { let c = base[j]; if c < 0x20 || c >= 0x7F { break }; j += 1 } }
                    var k = i
                    while k < j {
                        if pendingWrap || cx >= cols { cx = 0; linefeed(); pendingWrap = false }
                        let take = min(j - k, cols - cx); let p = rowPtr(cy) + cx
                        var t = 0; while t < take { p[t] = C(cp: UInt32(base[k + t]), wide: 0, style: style, id: styleId); t += 1 }
                        cx += take; k += take
                        if cx >= cols { cx = cols - 1; pendingWrap = true }
                    }
                    i = j
                } else if b < 0x20 {
                    switch b { case 0x0A, 0x0B, 0x0C: linefeed(); pendingWrap = false; case 0x0D: cx = 0; pendingWrap = false; case 0x08: if cx > 0 { cx -= 1 }; pendingWrap = false; case 0x09: cx = min(cols - 1, (cx / 8 + 1) * 8); pendingWrap = false; case 0x1B: state = 1; default: break }
                    i += 1
                } else if b >= 0x80 {
                    var cp: UInt32 = 0; var len = 0
                    if b >= 0xF0 { len = 4; cp = UInt32(b & 0x07) } else if b >= 0xE0 { len = 3; cp = UInt32(b & 0x0F) } else if b >= 0xC0 { len = 2; cp = UInt32(b & 0x1F) } else { i += 1; continue }
                    if i + len > n { i = n; continue }
                    for q in 1..<len { cp = cp << 6 | UInt32(base[i + q] & 0x3F) }
                    let w = Model<C>.width(cp); if w > 0 { put(cp, width: w) }
                    i += len
                } else { i += 1 }
            case 1:
                let b = base[i]; i += 1
                if b == 91 { state = 2; nparams = 0; cur = -1; csiPrivate = false } else if b == 93 || b == 80 || b == 95 || b == 94 || b == 88 { state = 3 } else { state = 0 }
            case 2:
                let b = base[i]; i += 1
                if b >= 0x30 && b <= 0x39 { cur = (cur < 0 ? 0 : cur) * 10 + Int(b - 0x30) }
                else if b == 59 || b == 58 { if nparams < 16 { params[nparams] = max(cur, 0); nparams += 1 }; cur = -1 }
                else if b == 63 || b == 62 || b == 61 || b == 60 { csiPrivate = true }
                else if b >= 0x40 && b <= 0x7E { if cur >= 0 || nparams > 0 { if nparams < 16 { params[nparams] = max(cur, 0); nparams += 1 } }; csiDispatch(b); state = 0 }
                else if b == 0x1B { state = 1 }
            case 3: let b = base[i]; i += 1; if b == 0x07 { state = 0 } else if b == 0x1B { state = 4 }
            default: state = base[i] == 92 ? 0 : 3; i += 1
            }
        }
    }
    func visibleChecksum() -> UInt64 { var h: UInt64 = 14695981039346656037; for y in 0..<rows { let p = rowPtr(y); for x in 0..<cols { h = (h ^ UInt64(p[x].cpValue) ^ UInt64(p[x].styleKey) << 21) &* 1099511628211 } }; return h ^ UInt64(sbCount) ^ UInt64(coldRows) << 20 }
    /// decode every cold row back to text; returns total bytes of text decoded (for timing)
    func decodeAllCold() -> Int {
        var i = 0; var total = 0; var rowsSeen = 0
        cold.withUnsafeBufferPointer { b in
            while i < b.count { let tl = Int(b[i]) | Int(b[i + 1]) << 8; i += 2; var s = 0; while s < tl { if b[i + s] < 0x80 { total += 1 }; s += 1 }; i += tl; let rc = Int(b[i]); i += 1 + rc * 3; rowsSeen += 1 }
        }
        precondition(rowsSeen == coldRows)
        return total
    }
}

