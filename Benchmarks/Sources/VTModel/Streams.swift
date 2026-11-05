// Deterministic ~1 MiB byte streams equivalent to vtebench's workloads at 120x40, generated in code (no files), ONLCR applied (\n -> \r\n).
package struct Lcg { var s: UInt64; mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s >> 33 } }
func bytes(_ s: String) -> [UInt8] { Array(s.utf8) }

package enum Streams {
    package static let target = 1 << 20
    package static let scrolling: [UInt8] = Array(repeating: [121, 13, 10], count: target / 3).flatMap { $0 }
    package static let fullscreen: [UInt8] = {
        var out: [UInt8] = []; var i = 0
        while out.count < target { out += Array(repeating: UInt8(65 + i % 26), count: 120); out += [13, 10]; i += 1 }
        return out
    }()
    package static let topRegion: [UInt8] = bytes("\u{1B}[?1049h\u{1B}[2;40r") + scrolling
    package static let denseCells: [UInt8] = {
        var out: [UInt8] = []; var offset = 0
        while out.count < target {
            for ch in 65..<91 {
                out += bytes("\u{1B}[H")
                for l in 1...40 { for c in 1...120 { let idx = l + c + offset; out += bytes("\u{1B}[38;5;\(idx % 156 + 100);48;5;\(255 - idx % 156 + 100);1;3;4m"); out.append(UInt8(ch)) } }
                offset += 1; if out.count >= target { break }
            }
        }
        return out
    }()
    /// Coloured log lines: words from a fixed vocabulary, half the lines with an SGR-coloured level tag, CRLF endings.
    package static let log: [UInt8] = {
        var r = Lcg(s: 3); var out: [UInt8] = []
        let words = ["struct", "func", "let", "var", "return", "buffer", "screen", "render", "cell", "style", "frame", "terminal", "input", "state", "update", "layout", "scroll", "region", "page", "row"]
        let tags = ["INFO", "WARN", "OK", "DEBUG"]; let colours = ["32", "31", "33", "36", "1;34", "38;5;208", "38;2;120;200;80"]
        while out.count < target {
            if r.next() % 2 == 0 { out += bytes("\u{1B}[\(colours[Int(r.next() % 7)])m[\(tags[Int(r.next() % 4)])]\u{1B}[0m ") }
            var line = ""; while line.utf8.count < 70 + Int(r.next() % 40) { line += words[Int(r.next() % UInt64(words.count))] + " " }
            out += bytes(line) + [13, 10]
        }
        return out
    }()
    /// Mixed ASCII, Latin-1, CJK (wide) and emoji (wide) scalars, CRLF every ~60 scalars.
    package static let unicode: [UInt8] = {
        var r = Lcg(s: 5); var out: [UInt8] = []; let scalars: [Unicode.Scalar] = ["a", "é", "ß", "漢", "字", "あ", "한", "😀", "🎉", "→", "★", "x"]
        while out.count < target { for _ in 0..<60 { out += Array(String(scalars[Int(r.next() % UInt64(scalars.count))]).utf8) }; out += [13, 10] }
        return out
    }()
}

func runChunked<C: CellType>(_ m: Model<C>, _ d: [UInt8]) {
    d.withUnsafeBufferPointer { bp in var o = 0; while o < bp.count { let e = min(bp.count, o + 65536); m.feed(UnsafeBufferPointer(rebasing: bp[o..<e])); o = e } }
}
