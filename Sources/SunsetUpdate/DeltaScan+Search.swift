extension DeltaScan {
    /// The longest match in the old file of the new file from `at`: its length and where it starts in the old file, by
    /// binary search of the suffix array.
    func longestMatch(at: Int) -> (length: Int, position: Int) {
        var start = 0
        var end = old.count
        while end - start >= 2 {
            let middle = start + (end - start) / 2
            if compare(oldFrom: suffixes[middle], newFrom: at) < 0 { start = middle } else { end = middle }
        }
        let first = matchLength(oldFrom: suffixes[start], newFrom: at)
        let second = matchLength(oldFrom: suffixes[end], newFrom: at)
        return first > second ? (first, suffixes[start]) : (second, suffixes[end])
    }

    /// How many bytes are equal from `oldFrom` and `newFrom`.
    private func matchLength(oldFrom: Int, newFrom: Int) -> Int {
        var length = 0
        while oldFrom + length < old.count, newFrom + length < new.count, old[oldFrom + length] == new[newFrom + length]
        {
            length += 1
        }
        return length
    }

    /// memcmp of the old from `oldFrom` and the new from `newFrom`, over the shorter of the two.
    private func compare(oldFrom: Int, newFrom: Int) -> Int {
        let length = min(old.count - oldFrom, new.count - newFrom)
        var index = 0
        while index < length {
            let left = old[oldFrom + index]
            let right = new[newFrom + index]
            if left != right { return left < right ? -1 : 1 }
            index += 1
        }
        return 0
    }
}
