/// The suffix array of a file (every suffix's start, in the order of the suffixes), by Larsson and Sadakane's
/// prefix-doubling sort, as bsdiff makes it: `order[0]` is the empty suffix's (the file's size).
struct SuffixSort {
    private(set) var order: [Int]
    private var rank: [Int]

    init(_ bytes: [UInt8]) {
        let size = bytes.count
        order = Array(repeating: 0, count: size + 1)
        rank = Array(repeating: 0, count: size + 1)
        var buckets = Array(repeating: 0, count: 256)
        for byte in bytes { buckets[Int(byte)] += 1 }
        for index in 1 ..< 256 { buckets[index] += buckets[index - 1] }
        for index in stride(from: 255, to: 0, by: -1) { buckets[index] = buckets[index - 1] }
        buckets[0] = 0
        for (index, byte) in bytes.enumerated() {
            buckets[Int(byte)] += 1
            order[buckets[Int(byte)]] = index
        }
        order[0] = size
        for (index, byte) in bytes.enumerated() { rank[index] = buckets[Int(byte)] }
        rank[size] = 0
        for index in 1 ..< 256 where buckets[index] == buckets[index - 1] + 1 { order[buckets[index]] = -1 }
        order[0] = -1
        sortGroups(size: size)
        for index in 0 ... size { order[rank[index]] = index }
    }

    /// Doubles the compared prefix until every group is one suffix (a negative `order` entry: a run of sorted ones).
    private mutating func sortGroups(size: Int) {
        var depth = 1
        while order[0] != -(size + 1) {
            var length = 0
            var index = 0
            while index < size + 1 {
                if order[index] < 0 {
                    length -= order[index]
                    index -= order[index]
                } else {
                    if length != 0 { order[index - length] = -length }
                    length = rank[order[index]] + 1 - index
                    split(start: index, length: length, depth: depth)
                    index += length
                    length = 0
                }
            }
            if length != 0 { order[index - length] = -length }
            depth += depth
        }
    }

    private func key(_ at: Int, _ depth: Int) -> Int {
        rank[order[at] + depth]
    }

    /// Sorts the group `start ..< start + length` by the ranks `depth` further.
    private mutating func split(start: Int, length: Int, depth: Int) {
        guard length >= 16 else { return selectionSplit(start: start, length: length, depth: depth) }
        let pivot = key(start + length / 2, depth)
        var less = 0
        var equal = 0
        for index in start ..< start + length {
            let value = key(index, depth)
            if value < pivot { less += 1 } else if value == pivot { equal += 1 }
        }
        let lower = start + less
        let upper = lower + equal
        partition(start: start, lower: lower, upper: upper, pivot: pivot, depth: depth)
        if lower > start { split(start: start, length: lower - start, depth: depth) }
        for index in lower ..< upper { rank[order[index]] = upper - 1 }
        if lower == upper - 1 { order[lower] = -1 }
        if start + length > upper { split(start: upper, length: start + length - upper, depth: depth) }
    }

    /// Moves the keys below `pivot` before `lower`, equal ones to `lower ..< upper`, the others after.
    private mutating func partition(start: Int, lower: Int, upper: Int, pivot: Int, depth: Int) {
        var index = start
        var equalAt = 0
        var greaterAt = 0
        while index < lower {
            let value = key(index, depth)
            if value < pivot {
                index += 1
            } else if value == pivot {
                order.swapAt(index, lower + equalAt)
                equalAt += 1
            } else {
                order.swapAt(index, upper + greaterAt)
                greaterAt += 1
            }
        }
        while lower + equalAt < upper {
            if key(lower + equalAt, depth) == pivot {
                equalAt += 1
            } else {
                order.swapAt(lower + equalAt, upper + greaterAt)
                greaterAt += 1
            }
        }
    }

    /// Small groups: repeatedly the smallest keys to the front.
    private mutating func selectionSplit(start: Int, length: Int, depth: Int) {
        var first = start
        while first < start + length {
            var count = 1
            var smallest = key(first, depth)
            var index = 1
            while first + index < start + length {
                let value = key(first + index, depth)
                if value < smallest {
                    smallest = value
                    count = 0
                }
                if value == smallest {
                    order.swapAt(first + count, first + index)
                    count += 1
                }
                index += 1
            }
            for offset in 0 ..< count { rank[order[first + offset]] = first + count - 1 }
            if count == 1 { order[first] = -1 }
            first += count
        }
    }
}
