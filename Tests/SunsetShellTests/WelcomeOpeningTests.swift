import CoreGraphics
import Testing

@testable import SunsetShellModel

/// The welcome's opening, as the owner asked (2026-11-21): the sun alone fades in, out of focus, slowly, with no sky and no
/// purple around it; then the real window fades in where it stands, its content coming into focus, and the sun passes
/// into the window's own. Nothing drawn stands in for the window.
@Suite("The welcome's opening")
struct WelcomeOpeningTests {
    private let frame = CGRect(x: 400, y: 200, width: 720, height: 470)
    private var times: [Double] {
        stride(from: 0, through: WelcomeOpening.duration + 0.5, by: 0.05).map(\.self)
    }

    private func at(_ time: Double) -> WelcomeOpening {
        WelcomeOpening.at(time, frame: frame)
    }

    @Test func `the sun sets: it appears higher, then goes down to where the window keeps it, before the window shows`()
    {
        let rest = CGPoint(x: frame.midX, y: frame.minY + frame.height * WelcomeOpening.sunHeight)
        // Low already (the owner: "should start lower on the screen"): under the window's middle, above its rest.
        #expect(at(0).sun.y > frame.minY + frame.height * 0.7 && at(0).sun.y < rest.y - frame.height * 0.08)
        var last = at(0)
        for time in times {
            let now = at(time)
            #expect(now.sun.x == rest.x, "straight down, at \(time)")
            #expect(now.sun.y >= last.sun.y - 0.001, "only down, at \(time)")
            last = now
        }
        let setting = WelcomeOpening.setPhase
        #expect(setting.start >= 1, "it is seen before it moves")
        // The window phases in as the sun settles: what is left of its way is imperceptible (the owner, 2026-11-21:
        // "almost imperceptible with the phasing in of the window"), and no pause between the two.
        let left = rest.y - at(WelcomeOpening.windowPhase.start).sun.y
        #expect(left < frame.height * 0.004, "\(left) points still to go")
        #expect(WelcomeOpening.windowPhase.start < setting.start + setting.length, "they overlap")
        for time in times where time >= setting.start + setting.length {
            #expect(at(time).sun == rest, "at \(time)")
        }
    }

    @Test func `the sun comes first, slowly, out of focus, and the window not before it is there`() {
        #expect(at(0).sunOpacity == 0)
        #expect(at(0.5).sunOpacity < 0.35, "not too fast")
        #expect(at(0.5).sunDefocus > 0.8)
        #expect(at(WelcomeOpening.windowPhase.start).sunOpacity > 0.9)
        for time in times where time <= WelcomeOpening.windowPhase.start {
            #expect(at(time).windowOpacity == 0, "at \(time)")
        }
        var last = at(0)
        for time in times {
            #expect(at(time).sunDefocus <= last.sunDefocus + 0.0001, "at \(time)")
            last = at(time)
        }
    }

    @Test func `then the window fades in, its content coming into focus, while the sun passes into it`() {
        let phase = WelcomeOpening.windowPhase
        #expect(phase.length >= 2)
        #expect(at(phase.start).contentBlur > 20)
        var last = at(phase.start)
        for time in times where time >= phase.start {
            let now = at(time)
            #expect(now.windowOpacity >= last.windowOpacity - 0.0001, "at \(time)")
            #expect(now.contentBlur <= last.contentBlur + 0.001, "at \(time)")
            #expect(now.sunOpacity <= last.sunOpacity + 0.0001, "at \(time)")
            last = now
        }
    }

    @Test func `every phase starts and ends gently: no jump in speed at either end`() {
        for phase in [WelcomeOpening.sunPhase, WelcomeOpening.setPhase, WelcomeOpening.windowPhase] {
            let step = 0.02
            let begin = abs(at(phase.start + step).sun.y - at(phase.start).sun.y)
            let middle = abs(at(phase.start + phase.length / 2 + step).sun.y - at(phase.start + phase.length / 2).sun.y)
            if middle > 0 { #expect(begin < middle * 0.1, "\(phase)") }
            let fadeBegin = at(phase.start + step).windowOpacity - at(phase.start).windowOpacity
            let fadeMiddle =
                at(phase.start + phase.length / 2 + step).windowOpacity
                - at(phase.start + phase.length / 2).windowOpacity
            if fadeMiddle > 0 { #expect(fadeBegin < fadeMiddle * 0.1, "\(phase)") }
        }
    }

    @Test func `the window comes slowly out of nothing: a tenth of its way in, barely there`() {
        let phase = WelcomeOpening.windowPhase
        #expect(at(phase.start + phase.length * 0.1).windowOpacity < 0.02)
        #expect(at(phase.start + phase.length * 0.5).windowOpacity > 0.3)
    }

    /// n86: "could the … sun itself in the animation be more circular a tiny bit … and morph while moving into the shape it
    /// should take on the window?"
    @Test func `the sun starts round and takes the window's shape as it sets, never back`() {
        #expect(at(0).sunRoundness == 1)
        let set = WelcomeOpening.setPhase
        #expect(at(set.start + set.length).sunRoundness < 1e-9, "the window's shape once it has set")
        #expect(
            at(set.start + set.length * 0.5).sunRoundness > 0.2 && at(set.start + set.length * 0.5).sunRoundness < 0.8
        )
        var last = at(0)
        for time in times {
            let now = at(time)
            #expect(now.sunRoundness <= last.sunRoundness, "only towards the window's shape, at \(time)")
            last = now
        }
        #expect(
            WelcomeOpening.sunAspect(roundness: 0) == WelcomeOpening.windowAspect
        )
        #expect(WelcomeOpening.sunAspect(roundness: 1) == CGSize(width: 1, height: 1))
    }

    @Test func `it ends as the window alone`() {
        let end = at(WelcomeOpening.duration)
        #expect(end.windowOpacity == 1 && end.contentBlur == 0 && end.sunOpacity == 0)
        #expect(at(WelcomeOpening.duration + 1) == end)
        #expect(WelcomeOpening.elevation(at: 0) < WelcomeOpening.elevation(at: WelcomeOpening.duration))
    }
}
