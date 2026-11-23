/// The terminal's identity.
public enum Sunset {
    /// The version the terminal reports to XTVERSION and in `TERM_PROGRAM_VERSION`: what a program reads to know what it can
    /// ask of the terminal. 0.1.0 draws kitty's Unicode image placeholders (roadmap 0010 E), which ask waits for before drawing
    /// pictures; a terminal before it said 0.0.1 to XTVERSION and nothing in the environment.
    public static let version: StaticString = "0.1.0"
}
