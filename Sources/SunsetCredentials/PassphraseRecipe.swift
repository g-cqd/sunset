internal import Foundation

/// Diceware-style memorable passphrase generator (roadmap 0092 F): picks uniformly from an embedded curated word list
/// using `RandomNumberGenerator`, with configurable word count, separator, optional capitalization, and optional digit.
public struct PassphraseRecipe: Sendable, Equatable {
    public var words: Int
    public var separator: String
    public var capitalize: Bool
    public var includeNumber: Bool

    public init(words: Int = 5, separator: String = "-", capitalize: Bool = false, includeNumber: Bool = false) {
        self.words = max(2, min(words, 12))
        self.separator = separator
        self.capitalize = capitalize
        self.includeNumber = includeNumber
    }

    public func generate(using generator: inout some RandomNumberGenerator) -> String {
        let list = Self.wordList
        var chosen: [String] = []
        chosen.reserveCapacity(words)
        let digitSlot = includeNumber ? Int.random(in: 0 ..< words, using: &generator) : -1
        for slot in 0 ..< words {
            var word = list[Int.random(in: 0 ..< list.count, using: &generator)]
            if capitalize { word = word.prefix(1).uppercased() + word.dropFirst() }
            if slot == digitSlot {
                word += String(Int.random(in: 0 ... 9, using: &generator))
            }
            chosen.append(word)
        }
        return chosen.joined(separator: separator)
    }

    /// Estimated entropy in bits for this recipe (word choices + optional digit position & digit value).
    public var entropyBits: Double {
        let perWord = log2(Double(Self.wordList.count))
        let digitBits = includeNumber ? log2(Double(words * 10)) : 0
        return Double(words) * perWord + digitBits
    }

    /// 256 short, distinct, easy-to-type English words (8 bits per word -> 5 words = 40+ bits, 6 words = 48+ bits).
    static let wordList: [String] =
        """
        acorn amber anchor anvil apple apron arrow aspen atlas attic audio autumn badge baker banjo basil basin batch
        beach cedar berry birch bison blade blaze bloom board boatman cabin cable cactus camel canal candy canoe canon
        canyon caper cargo carol carry carve castle cedar cello chalk charm chart chase chess chime cider cigar cinch
        civic claim clamp clash clasp clean clear cleft clerk cliff climb cling cloak clock clone close cloth cloud
        clove clown coach coast cobra cocoa comet comic coral couch count court cover craft crane crash crate crave
        crawl craze creek crest crisp croft cross crowd crown crush crust crypt cubic cumin curve cycle daisy dance
        delta denim depot depth derby devil diary digit diner dingo disco ditch diver dizzy dodge dogma dolly donor
        doubt dough dover dozen draft drain drake drama drank drape drawn dread dream dress drift drill drink drive
        droit droll drone drool droop dross drove drown druid dryad dully dummy dumpy dunce dusky dusty dutch dwarf
        dwell dwelt dying eager eagle early earth easel eaten ebony edict egret eight eject elbow elder elect elfin
        elide elite elope elude email ember emcee empty enact endow enema enemy enjoy ennui ensue enter entry envoy
        epoch epoxy equal equip erase erect erode error erupt essay ester ether ethic ethos etude evade event every
        evict evoke exact exalt excel exert exile exist expel extol extra exult fable facet facto faint fairy faith
        false fancy fanny farce fatal fatty fault fauna favor feast fecal feign fella felon femme femur fence feral
        ferry fetal fetch fetid fetus fever fewer fiber fibre ficus field fiend fiery fifth fifty fight filer filet
        filly filmy filth final finch finer first fishy fixer fizzy fjord flack flail flair flake flaky flame flank
        flare flash flask fleck fleet flesh flick flier fling flint flirt float flock flood floor flora floss flour
        flout flown fluff fluid fluke flume flung flunk flush flute flyer foist folio folly foray force forge forgo
        forte forth forty forum found foyer frail frame frank fraud freak freed freer fresh friar fried frill frisk
        """
        .split(whereSeparator: { $0.isWhitespace })
        .map(String.init)
}
