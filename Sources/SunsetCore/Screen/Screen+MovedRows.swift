extension Screen {
    /// Where the cells of `row` were at the last `clearDirty`, when the only change since is that scrolling moved them (a line feed at the bottom, a scroll,
    /// inserted or deleted lines): a renderer can move that row's pixels instead of drawing it. nil when the row was written since or came in blank. A row
    /// that is not dirty is where it was.
    public func movedFrom(row: Int) -> Int? {
        let origin = rowOrigins[row]
        return origin < 0 ? nil : Int(origin)
    }
}
