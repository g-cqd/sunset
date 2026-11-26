import SunsetHost

/// Kitty image animations, played on this terminal's runtime while it is shown (`AnimationPlayback`).
extension TerminalModel {
    func animate(_ session: TerminalSession) async {
        await AnimationPlayback.run(
            runtime: runtime,
            wakes: wakes.animation.stream,
            wake: wakes.animation.continuation,
            isVisible: { [weak self] in self?.isVisible ?? false },
            advance: { session.advanceAnimations(nowMilliseconds: $0) },
            changed: { [weak self] in self?.requestFrame() }
        )
    }
}
