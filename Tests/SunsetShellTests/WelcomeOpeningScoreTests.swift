import Foundation
import Testing

@testable import SunsetShellModel

/// The welcome opening's score: a dark, low-frequency atmospheric swell that matches the opening's phases
/// (`WelcomeOpening`) — rising out of silence with the sun, building tension as it descends, opening its harmonic veil
/// into the window transition, and settling gently into silence.
@Suite("The welcome opening's score")
struct WelcomeOpeningScoreTests {
    private let sampleRate = 48_000.0

    /// Renders `duration` seconds of the score into interleaved stereo samples (L, R, L, R, …).
    private func render(duration: Double = WelcomeOpeningScore.duration) -> [Float] {
        var score = WelcomeOpeningScore(sampleRate: sampleRate)
        let frames = Int((duration * sampleRate).rounded())
        var stereo = [Float](repeating: 0, count: frames * 2)
        for frame in 0 ..< frames {
            let (left, right) = score.nextSample()
            stereo[frame * 2] = left
            stereo[frame * 2 + 1] = right
        }
        return stereo
    }

    private func rms(of stereo: [Float], from startSeconds: Double, to endSeconds: Double) -> Double {
        let start = max(0, Int((startSeconds * sampleRate).rounded()))
        let end = min(stereo.count / 2, Int((endSeconds * sampleRate).rounded()))
        guard end > start else { return 0 }
        var sum = 0.0
        for frame in start ..< end {
            let left = Double(stereo[frame * 2])
            let right = Double(stereo[frame * 2 + 1])
            sum += 0.5 * (left * left + right * right)
        }
        return (sum / Double(end - start)).squareRoot()
    }

    @Test func `every sample is finite, within headroom, and silent before and after the score`() {
        let stereo = render(duration: WelcomeOpeningScore.duration + 0.5)
        var peak: Float = 0
        for sample in stereo {
            #expect(sample.isFinite)
            peak = max(peak, abs(sample))
        }
        #expect(peak > 0.15, "audible level: \(peak)")
        #expect(peak <= 0.95, "no clipping: \(peak)")
        // Starts from silence (no click at t = 0) and finishes in silence.
        #expect(abs(stereo[0]) < 1e-4 && abs(stereo[1]) < 1e-4)
        let tail = rms(of: stereo, from: WelcomeOpeningScore.duration + 0.05, to: WelcomeOpeningScore.duration + 0.45)
        #expect(tail < 1e-4, "silent after the tail: \(tail)")
    }

    @Test func `energy follows the opening phases: grows with the sun, peaks into the window, then releases`() {
        let stereo = render()
        let onset = rms(of: stereo, from: 0.0, to: 0.35)
        let sunAppear = rms(of: stereo, from: 1.0, to: 2.6)
        let settingSwell = rms(of: stereo, from: 3.2, to: 4.9)
        let windowCrossfade = rms(of: stereo, from: 5.0, to: 6.4)
        let release = rms(of: stereo, from: 7.4, to: 8.6)
        #expect(onset < sunAppear * 0.4, "rises gently out of silence: \(onset) vs \(sunAppear)")
        #expect(settingSwell > sunAppear * 1.15, "builds as the sun descends: \(settingSwell) vs \(sunAppear)")
        #expect(windowCrossfade > sunAppear, "present across the window reveal: \(windowCrossfade) vs \(sunAppear)")
        #expect(release < windowCrossfade * 0.55, "fades away as the window settles: \(release) vs \(windowCrossfade)")
    }

    @Test func `most of the energy sits in the low frequencies`() {
        // Measure spectral balance during the main sustain (2.0..5.5 s) using a simple one-pole split at 350 Hz.
        let stereo = render()
        let start = Int(2.0 * sampleRate)
        let end = Int(5.5 * sampleRate)
        let alpha = 1.0 - exp(-2.0 * .pi * 350.0 / sampleRate)
        var lowState = 0.0
        var lowEnergy = 0.0
        var highEnergy = 0.0
        for frame in start ..< end {
            let mono = 0.5 * (Double(stereo[frame * 2]) + Double(stereo[frame * 2 + 1]))
            lowState += alpha * (mono - lowState)
            let high = mono - lowState
            lowEnergy += lowState * lowState
            highEnergy += high * high
        }
        let lowShare = lowEnergy / max(lowEnergy + highEnergy, 1e-12)
        #expect(lowShare > 0.72, "low-frequency dominant: \(lowShare)")
    }

    @Test func `the window transition opens the upper harmonics compared to the sun's first appearance`() {
        let stereo = render()
        let alpha = 1.0 - exp(-2.0 * .pi * 220.0 / sampleRate)
        func brightness(from startSeconds: Double, to endSeconds: Double) -> Double {
            let start = Int(startSeconds * sampleRate)
            let end = Int(endSeconds * sampleRate)
            var low = 0.0
            var total = 0.0
            var upper = 0.0
            for frame in start ..< end {
                let mono = 0.5 * (Double(stereo[frame * 2]) + Double(stereo[frame * 2 + 1]))
                low += alpha * (mono - low)
                let high = mono - low
                total += mono * mono
                upper += high * high
            }
            return upper / max(total, 1e-12)
        }
        let early = brightness(from: 0.6, to: 2.2)
        let reveal = brightness(from: 5.0, to: 6.4)
        #expect(reveal > early * 1.35, "filter opens into the window: \(reveal) vs \(early)")
    }

    @Test func `stereo width exists without severe phase cancellation`() {
        let stereo = render()
        let start = Int(2.5 * sampleRate)
        let end = Int(6.0 * sampleRate)
        var midEnergy = 0.0
        var sideEnergy = 0.0
        for frame in start ..< end {
            let left = Double(stereo[frame * 2])
            let right = Double(stereo[frame * 2 + 1])
            let mid = 0.5 * (left + right)
            let side = 0.5 * (left - right)
            midEnergy += mid * mid
            sideEnergy += side * side
        }
        #expect(sideEnergy > midEnergy * 0.02, "noticeable stereo spread")
        #expect(midEnergy > sideEnergy * 2.0, "solid mono-compatible low end")
    }

    @Test func `sustained piano and flute layers add gentle dissonance and harmonic motion through the transition`() {
        // Sample the harmonic spectrum in the 140..420 Hz band (where the felted piano dyad, dissonant seconds,
        // and breathy dark flute sit) during early sun appearance vs. descent and window transition.
        let stereo = render()
        func bandEnergy(lowHz: Double, highHz: Double, from startSeconds: Double, to endSeconds: Double) -> Double {
            let start = Int(startSeconds * sampleRate)
            let end = Int(endSeconds * sampleRate)
            let alphaLow = 1.0 - exp(-2.0 * .pi * lowHz / sampleRate)
            let alphaHigh = 1.0 - exp(-2.0 * .pi * highHz / sampleRate)
            var lpLow = 0.0
            var lpHigh = 0.0
            var energy = 0.0
            for frame in start ..< end {
                let mono = 0.5 * (Double(stereo[frame * 2]) + Double(stereo[frame * 2 + 1]))
                lpLow += alphaLow * (mono - lpLow)
                lpHigh += alphaHigh * (mono - lpHigh)
                let band = lpHigh - lpLow
                energy += band * band
            }
            return (energy / Double(max(1, end - start))).squareRoot()
        }
        let earlyWarmth = bandEnergy(lowHz: 140, highHz: 420, from: 0.4, to: 1.4)
        let descentHarmonics = bandEnergy(lowHz: 140, highHz: 420, from: 2.0, to: 4.8)
        let transitionBloom = bandEnergy(lowHz: 140, highHz: 420, from: 5.0, to: 6.8)
        #expect(
            descentHarmonics > earlyWarmth * 1.8,
            "piano and flute enter during the descent: \(descentHarmonics) vs \(earlyWarmth)"
        )
        #expect(
            transitionBloom > descentHarmonics * 1.15,
            "harmonic bloom opens further into the window: \(transitionBloom) vs \(descentHarmonics)"
        )
    }

    @Test func `cancelling early fades out smoothly to silence without a click`() {
        var score = WelcomeOpeningScore(sampleRate: sampleRate)
        let cutFrame = Int(3.5 * sampleRate)
        for _ in 0 ..< cutFrame { _ = score.nextSample() }
        let before = score.nextSample()
        score.fadeOut()
        var maxJump: Float = 0
        var prevL = before.left
        var prevR = before.right
        var endLevel: Float = 0
        let tailFrames = Int(0.6 * sampleRate)
        for index in 0 ..< tailFrames {
            let sample = score.nextSample()
            maxJump = max(maxJump, abs(sample.left - prevL), abs(sample.right - prevR))
            prevL = sample.left
            prevR = sample.right
            if index > tailFrames - 1000 { endLevel = max(endLevel, abs(sample.left), abs(sample.right)) }
        }
        #expect(maxJump < 0.05, "no step discontinuity: \(maxJump)")
        #expect(endLevel < 1e-4, "reaches silence after cancel: \(endLevel)")
        #expect(score.isFinished)
    }
}
