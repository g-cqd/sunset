/// How a string ended: by BEL, by ST (ESC \\ or U+009C, or an ESC that began another sequence), or not at all (cancelled by CAN or SUB).
/// A reply to a query should end the way the query did.
public enum StringTerminator: UInt8, Sendable {
    case bel, st, none
}
