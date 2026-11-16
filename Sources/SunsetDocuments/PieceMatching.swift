/// Which pieces of one text are still pieces of another (roadmap 0023 step M-e): the longest run of pieces in the same
/// order, found without comparing every piece with every other.
///
/// The common start and end are set aside; then the pieces that occur exactly once on each side and are the same (most
/// blocks of a document are) are taken as fixed points, in the longest order they agree on; what lies between two fixed
/// points is compared in full while a budget of comparisons lasts, then place by place when it is as long on both sides, and
/// otherwise counts as replaced. So two texts of n pieces that differ in d cost O(n + d^2) and never more than the budget,
/// and a text edited in two places far apart is not one long change.
enum PieceMatching {
    /// Which piece of `side` each piece of `base` still is.
    /// - Parameters:
    ///   - base: the pieces of before.
    ///   - side: the pieces of after.
    ///   - budget: how many pairs of pieces may be compared in full, over all that lies between the fixed points.
    /// - Returns: for each piece of `base`, its place in `side`, or nil when it was replaced or removed; the places go up.
    static func image<Piece: Hashable>(base: [Piece], side: [Piece], budget: Int) -> [Int?] {
        var image = [Int?](repeating: nil, count: base.count)
        var start = 0
        while start < base.count, start < side.count, base[start] == side[start] {
            image[start] = start
            start += 1
        }
        var end = 0
        while end < base.count - start, end < side.count - start,
            base[base.count - 1 - end] == side[side.count - 1 - end]
        {
            image[base.count - 1 - end] = side.count - 1 - end
            end += 1
        }
        let baseEnd = base.count - end
        let sideEnd = side.count - end
        var left = budget
        var from = (base: start, side: start)
        for anchor in anchors(base[start ..< baseEnd], side[start ..< sideEnd]) + [(base: baseEnd, side: sideEnd)] {
            between(base[from.base ..< anchor.base], side[from.side ..< anchor.side], budget: &left, into: &image)
            if anchor.base < baseEnd { image[anchor.base] = anchor.side }
            from = (anchor.base + 1, anchor.side + 1)
        }
        return image
    }

    /// The pieces that are once in each and the same, in the longest order both agree on.
    private static func anchors<Piece: Hashable>(
        _ base: ArraySlice<Piece>,
        _ side: ArraySlice<Piece>
    ) -> [(base: Int, side: Int)] {
        guard !base.isEmpty, !side.isEmpty else { return [] }
        // Where each piece of the side is, or -1 when it is there more than once.
        var places: [Piece: Int] = [:]
        places.reserveCapacity(side.count)
        for index in side.indices { places[side[index]] = places[side[index]] == nil ? index : -1 }
        var seen: [Piece: Int] = [:]
        seen.reserveCapacity(base.count)
        for index in base.indices { seen[base[index], default: 0] += 1 }
        var pairs: [(base: Int, side: Int)] = []
        for index in base.indices where seen[base[index]] == 1 {
            if let place = places[base[index]], place >= 0 { pairs.append((index, place)) }
        }
        return longestIncreasing(pairs)
    }

    /// The longest run of `pairs` (in the order of the base) whose places on the side also go up.
    /// - Complexity: O(n log n).
    private static func longestIncreasing(_ pairs: [(base: Int, side: Int)]) -> [(base: Int, side: Int)] {
        // tails[k]: the pair that ends the best run of k + 1 found so far; before[i]: the pair before pair i in its run.
        var tails: [Int] = []
        var before = [Int](repeating: -1, count: pairs.count)
        for index in pairs.indices {
            var low = 0
            var high = tails.count
            while low < high {
                let middle = (low + high) / 2
                if pairs[tails[middle]].side < pairs[index].side { low = middle + 1 } else { high = middle }
            }
            if low > 0 { before[index] = tails[low - 1] }
            if low == tails.count { tails.append(index) } else { tails[low] = index }
        }
        var run: [(base: Int, side: Int)] = []
        var index = tails.last ?? -1
        while index >= 0 {
            run.append(pairs[index])
            index = before[index]
        }
        return run.reversed()
    }

    /// What lies between two fixed points: compared in full within the budget; else place by place when as long on both
    /// sides; else nothing of it is the same.
    private static func between<Piece: Hashable>(
        _ base: ArraySlice<Piece>,
        _ side: ArraySlice<Piece>,
        budget: inout Int,
        into image: inout [Int?]
    ) {
        guard !base.isEmpty, !side.isEmpty else { return }
        guard base.count <= budget / side.count else {
            if base.count == side.count {
                for offset in 0 ..< base.count where base[base.startIndex + offset] == side[side.startIndex + offset] {
                    image[base.startIndex + offset] = side.startIndex + offset
                }
            }
            return
        }
        budget -= base.count * side.count
        var removed = Set<Int>()
        var inserted = Set<Int>()
        for change in Array(side).difference(from: Array(base)) {
            switch change {
                case .remove(let offset, _, _): removed.insert(offset)
                case .insert(let offset, _, _): inserted.insert(offset)
            }
        }
        var target = 0
        for offset in 0 ..< base.count where !removed.contains(offset) {
            while inserted.contains(target) { target += 1 }
            image[base.startIndex + offset] = side.startIndex + target
            target += 1
        }
    }
}
