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

    @Test func `the sun stays where the window's sky keeps it`() {
        let sun = CGPoint(x: frame.midX, y: frame.minY + frame.height * WelcomeOpening.sunHeight)
        for time in times { #expect(at(time).sun == sun, "at \(time)") }
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

    @Test func `it ends as the window alone`() {
        let end = at(WelcomeOpening.duration)
        #expect(end.windowOpacity == 1 && end.contentBlur == 0 && end.sunOpacity == 0)
        #expect(at(WelcomeOpening.duration + 1) == end)
        #expect(WelcomeOpening.elevation(at: 0) < WelcomeOpening.elevation(at: WelcomeOpening.duration))
    }
}
