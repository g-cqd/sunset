/// bsdiff's scan of the new file against the old one's suffix array: where a long match starts, the run since the last
/// one is split into "old plus differences" forward from the last match, new bytes, and "old plus differences" backward
/// from this match.
struct DeltaScan {
    struct Control: Equatable {
        let add: Int
        let copy: Int
        let seek: Int
    }

    struct Found {
        var controls: [Control] = []
        var difference: [UInt8] = []
        var extra: [UInt8] = []
    }

    let old: [UInt8]
    let new: [UInt8]
    let suffixes: [Int]

    init(old: [UInt8], new: [UInt8]) {
        self.old = old
        self.new = new
        suffixes = SuffixSort(old).order
    }

    /// Where the scan is: the end of the last match in both files, and the offset between them.
    private struct Mark {
        var scan = 0
        var position = 0
        var offset = 0
    }

    func run() -> Found {
        var found = Found()
        var last = Mark()
        var scan = 0
        var length = 0
        var position = 0
        while scan < new.count {
            var oldScore = 0
            scan += length
            var scored = scan
            while scan < new.count {
                (length, position) = longestMatch(at: scan)
                while scored < scan + length {
                    if scored + last.offset < old.count, old[scored + last.offset] == new[scored] { oldScore += 1 }
                    scored += 1
                }
                if (length == oldScore && length != 0) || length > oldScore + 8 { break }
                if scan + last.offset < old.count, old[scan + last.offset] == new[scan] { oldScore -= 1 }
                scan += 1
            }
            if length != oldScore || scan == new.count {
                last = emit(from: last, scan: scan, position: position, into: &found)
            }
        }
        return found
    }

    /// The control for the run from `last` to the match at `scan` (in the new) and `position` (in the old).
    private func emit(from last: Mark, scan: Int, position: Int, into found: inout Found) -> Mark {
        var forward = forwardLength(from: last, scan: scan)
        var backward = scan < new.count ? backwardLength(from: last, scan: scan, position: position) : 0
        if last.scan + forward > scan - backward {
            let overlap = (last.scan + forward) - (scan - backward)
            var score = 0
            var best = 0
            var kept = 0
            for index in 0 ..< overlap {
                if new[last.scan + forward - overlap + index] == old[last.position + forward - overlap + index] {
                    score += 1
                }
                if new[scan - backward + index] == old[position - backward + index] { score -= 1 }
                if score > best {
                    best = score
                    kept = index + 1
                }
            }
            forward += kept - overlap
            backward -= kept
        }
        for index in 0 ..< forward { found.difference.append(new[last.scan + index] &- old[last.position + index]) }
        let copied = (scan - backward) - (last.scan + forward)
        found.extra.append(contentsOf: new[(last.scan + forward) ..< (last.scan + forward + copied)])
        let seek = (position - backward) - (last.position + forward)
        found.controls.append(Control(add: forward, copy: copied, seek: seek))
        return Mark(scan: scan - backward, position: position - backward, offset: position - scan)
    }

    /// How far forward from the last match "old plus differences" pays: more than half the bytes equal.
    private func forwardLength(from last: Mark, scan: Int) -> Int {
        var score = 0
        var best = 0
        var length = 0
        var index = 0
        while last.scan + index < scan, last.position + index < old.count {
            if old[last.position + index] == new[last.scan + index] { score += 1 }
            index += 1
            if score * 2 - index > best * 2 - length {
                best = score
                length = index
            }
        }
        return length
    }

    /// How far backward from this match "old plus differences" pays.
    private func backwardLength(from last: Mark, scan: Int, position: Int) -> Int {
        var score = 0
        var best = 0
        var length = 0
        var index = 1
        while scan >= last.scan + index, position >= index {
            if old[position - index] == new[scan - index] { score += 1 }
            if score * 2 - index > best * 2 - length {
                best = score
                length = index
            }
            index += 1
        }
        return length
    }
}
