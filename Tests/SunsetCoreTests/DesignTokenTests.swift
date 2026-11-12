import Testing

/// Views name their measures (design 0003 §8). The files written before the tokens are allowed until they are moved; the list only shrinks.
@Suite("Design tokens in views") struct DesignTokenTests {
    @Test func `a literal measure is found; 0, names and comments are not`() {
        #expect(DesignTokenScan.findings(in: "x.padding(.horizontal, 6)").count == 1)
        #expect(DesignTokenScan.findings(in: "VStack(spacing: 4) {").count == 1)
        #expect(DesignTokenScan.findings(in: "RoundedRectangle(cornerRadius: 12, style: .continuous)").count == 1)
        #expect(DesignTokenScan.findings(in: ".opacity(0.07)").count == 1)
        #expect(DesignTokenScan.findings(in: ".font(.system(size: 13))").count == 1)
        #expect(DesignTokenScan.findings(in: "x.padding(.horizontal, layout.tabSideInset + 8)").count == 1)
        #expect(DesignTokenScan.findings(in: "VStack(spacing: 0) {").isEmpty)
        #expect(DesignTokenScan.findings(in: ".opacity(hovering ? 1 : 0)").isEmpty)
        #expect(DesignTokenScan.findings(in: ".padding(Design.Space.s)").isEmpty)
        #expect(DesignTokenScan.findings(in: ".padding(space2)").isEmpty)
        #expect(DesignTokenScan.findings(in: "// .padding(6)").isEmpty)
        #expect(DesignTokenScan.findings(in: "HStack(spacing: Design.Space.xs) { Text(\"8\") }").isEmpty)
    }

    @Test func `every view names its measures, except the files not moved yet; the list only shrinks`() {
        let found = DesignTokenScan.repository()
        let new = found.keys.filter { !DesignTokenAllowance.files.contains($0) }.sorted()
        #expect(
            new.isEmpty,
            "measures written as numbers (use Design):\n\(new.map { "\($0): \(found[$0] ?? [])" }.joined(separator: "\n"))"
        )
        let moved = DesignTokenAllowance.files.filter { found[$0] == nil }.sorted()
        #expect(
            moved.isEmpty,
            "these files have no literal measures left: remove them from DesignTokenAllowance: \(moved)"
        )
    }
}
