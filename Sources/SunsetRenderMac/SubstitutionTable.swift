/// A substitution table, asked how a run made only of some glyphs could be changed (`SubstitutionReach`).
protocol SubstitutionTable: Sendable {
    func firings(within glyphs: Set<UInt16>) throws(FontTableBytes.Malformed) -> [SubstitutionReach.Firing]
}
