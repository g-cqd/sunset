/// What a pane's sound is doing (a web page): shown as a speaker on its tab, which mutes and unmutes it.
package enum PaneSound: Equatable, Sendable {
    case playing, muted

    package var symbol: String {
        self == .muted ? "speaker.slash.fill" : "speaker.wave.2.fill"
    }
    package var help: String {
        self == .muted ? "Unmute This Tab" : "Mute This Tab"
    }
}
