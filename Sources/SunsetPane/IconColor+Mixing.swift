extension IconColor {
    /// This colour mixed into another, channel by channel: `share` of this one, the rest of `base` (red, green, blue). A
    /// base that is not three channels is no colour to mix into, and this colour is returned whole.
    public func mixed(into base: [UInt8], share: Double) -> [UInt8] {
        guard base.count == 3 else { return [red, green, blue] }
        let part = min(max(share, 0), 1)
        return zip([red, green, blue], base)
            .map { mine, theirs in
                UInt8((Double(mine) * part + Double(theirs) * (1 - part)).rounded())
            }
    }
}
