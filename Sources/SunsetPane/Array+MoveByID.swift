extension Array where Element: Identifiable {
    /// Moves the element with `id` to `index`, brought inside the array; true when it was there (the tabs' order, the
    /// extensions' order).
    @discardableResult
    public mutating func move(id: Element.ID, to index: Int) -> Bool {
        guard let from = firstIndex(where: { $0.id == id }) else { return false }
        let element = remove(at: from)
        insert(element, at: Swift.min(Swift.max(index, 0), count))
        return true
    }
}
