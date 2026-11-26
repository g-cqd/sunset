/// Which glyphs shaping can never change, in any run made only of them: the proof behind the ASCII fast path for fonts
/// with substitution tables (t241). Each table (`GSUBReach`, `MorxReach`) lists the ways a run drawn from a set could be
/// changed (`Firing`), over-approximated: a rule is taken to fire when each of its positions could hold a glyph of the
/// set. Glyphs are taken out until nothing can fire. Then no substitution applies to any such run, so none changes the
/// run for a later one either, and each glyph stays its own.
enum SubstitutionReach {
    /// One way the glyphs of a run could be changed. It can no longer happen once every glyph of any one of
    /// `alternatives` is taken out of the set (a rule position left with nothing to match).
    struct Firing: Sendable, Equatable {
        var alternatives: [Set<UInt16>]
    }

    /// The most firings a table may list for one set: more is taken for a hostile table (`Malformed`), not walked.
    static let budget = 1 << 16

    /// The glyphs left once nothing in `tables` can fire within them, taking out the cheapest alternative of each firing
    /// (`cost`: what losing a glyph costs). Monotone: taking glyphs out never makes a rule fire, so this ends.
    static func unchanged(
        _ glyphs: Set<UInt16>,
        tables: [any SubstitutionTable],
        cost: (Set<UInt16>) -> Int
    ) throws(FontTableBytes.Malformed) -> Set<UInt16> {
        var kept = glyphs
        while !kept.isEmpty {
            var firings: [Firing] = []
            for table in tables { firings += try table.firings(within: kept) }
            if firings.isEmpty { return kept }
            let before = kept.count
            for firing in firings {
                let live = firing.alternatives.map { $0.intersection(kept) }
                guard !live.contains(where: \.isEmpty) else { continue }
                if let cheapest = live.min(by: { cost($0) < cost($1) }) { kept.subtract(cheapest) }
            }
            // A firing with no alternative at all can only be stopped by having no run.
            if kept.count == before { return [] }
        }
        return kept
    }

    /// Whether CoreText applies the OpenType feature `tag` with `settings` stated, for horizontal text: features the
    /// OpenType feature registry says are off by default, or for the user or application to apply on a trigger a run of
    /// ASCII has not, only when turned on; every other feature, a font's own unregistered ones included, as applied.
    /// Of those, only `liga`, `clig` and `calt` count as turned off by a 0 setting (Sunset states them; see
    /// `CoreTextFastPathTests`).
    static func isApplied(_ tag: String, settings: [FontFeature]) -> Bool {
        let stated = settings.last { $0.tag == tag }
        if let stated, stated.value >= 1 { return true }
        if let stated, stated.value == 0, ["liga", "clig", "calt"].contains(tag) { return false }
        return !offUnlessAsked(tag)
    }

    private static func offUnlessAsked(_ tag: String) -> Bool {
        let bytes = Array(tag.utf8)
        if bytes.count == 4, tag.hasPrefix("cv") || tag.hasPrefix("ss"),
            bytes.dropFirst(2).allSatisfy({ (0x30 ... 0x39).contains($0) })
        {
            return true
        }
        return offByDefault.contains(tag)
    }

    /// From the registry (features "off by default" or "inactive by default"; `aalt`, chosen by the user; `zero`, which
    /// most applications disable; `case`, `numr`, `dnom`, applied by an application; the vertical-only features).
    private static let offByDefault = Set(
        """
        aalt afrc apkn c2pc c2sc case cpct cswh dlig dnom frac fwid hist hkna hlig hngl hojo hwid jp04 jp78
        jp83 jp90 lfbd lnum mgrk nalt nlck numr onum ordn ornm palt pcap pkna pnum qwid rtbd ruby salt sinf
        smcp smpl subs sups swsh titl tnam tnum trad twid unic valt vapk vert vhal vkna vkrn vpal vrt2 vrtr
        zero
        """
        .split(whereSeparator: \.isWhitespace).map(String.init)
    )
}
