import Foundation
import Testing

@testable import SunsetShellModel

/// The welcome opening's score (`WelcomeOpeningScore`): a unified, warm consonant blend of low-mid bass, bowed
/// electronic strings, softly sustained felted piano, and an airy flute that blooms early with the sun, lifts off into
/// a diffused cloud across the window transition, and dissolves cleanly into silence with nothing below 20 Hz.
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
        #expect(peak > 0.25, "audible level: \(peak)")
        #expect(peak <= 0.95, "no clipping: \(peak)")
        #expect(abs(stereo[0]) < 1e-4 && abs(stereo[1]) < 1e-4)
        let tail = rms(of: stereo, from: WelcomeOpeningScore.duration + 0.05, to: WelcomeOpeningScore.duration + 0.45)
        #expect(tail < 1e-4, "silent after the tail: \(tail)")
    }

    @Test func `reaches full bloom early, lifts through the window reveal, and dissolves cleanly into silence`() {
        let stereo = render()
        let onset = rms(of: stereo, from: 0.0, to: 0.4)
        let earlyBloom = rms(of: stereo, from: 1.5, to: 2.8)
        let liftOff = rms(of: stereo, from: 3.8, to: 5.4)
        let lateTail = rms(of: stereo, from: 7.4, to: 9.2)
        #expect(onset < earlyBloom * 0.25, "smooth onset from silence: \(onset) vs \(earlyBloom)")
        #expect(earlyBloom > 0.10, "reaches strong presence early: \(earlyBloom)")
        #expect(liftOff > earlyBloom * 0.95, "carries luminous lift-off into the window: \(liftOff) vs \(earlyBloom)")
        #expect(lateTail < liftOff * 0.08, "diffuses cleanly into silence: \(lateTail) vs \(liftOff)")
    }

    @Test func `produces virtually no energy at or below 20 Hz`() {
        let stereo = render()
        let start = 0
        let end = Int(5.0 * sampleRate)
        let count = end - start
        var totalSq = 0.0
        for frame in start ..< end {
            let mono = 0.5 * (Double(stereo[frame * 2]) + Double(stereo[frame * 2 + 1]))
            totalSq += mono * mono
        }
        let totalRMS = (totalSq / Double(count)).squareRoot()
        for hz in [5.0, 10.0, 15.0, 18.0, 20.0] {
            var cosSum = 0.0
            var sinSum = 0.0
            let omega = 2.0 * .pi * hz / sampleRate
            var samples = 0
            // 8x decimation (6 kHz effective rate) is exact for frequencies <= 20 Hz.
            for frame in stride(from: start, to: end, by: 8) {
                let win = 0.5 * (1.0 - cos(2.0 * .pi * Double(frame - start) / Double(count - 1)))
                let mono = 0.5 * (Double(stereo[frame * 2]) + Double(stereo[frame * 2 + 1])) * win
                let angle = omega * Double(frame)
                cosSum += mono * cos(angle)
                sinSum += mono * sin(angle)
                samples += 1
            }
            let mag = 2.0 * hypot(cosSum, sinSum) / Double(samples)
            let db = 20.0 * log10(max(mag, 1e-12) / max(totalRMS, 1e-12))
            #expect(db < -70.0, "no sub-20 Hz energy at \(hz) Hz: \(db) dB")
        }
    }

    @Test func `upper harmonic lift-off brightens relative to the low end during the transition`() {
        let stereo = render()
        let alpha = 1.0 - exp(-2.0 * .pi * 240.0 / sampleRate)
        func upperShare(from startSeconds: Double, to endSeconds: Double) -> Double {
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
        let early = upperShare(from: 0.6, to: 1.8)
        let lift = upperShare(from: 3.6, to: 5.4)
        #expect(lift > early * 2.0, "lift-off shifts upward into upper harmonics: \(lift) vs \(early)")
    }

    @Test func `stereo width exists without severe phase cancellation`() {
        let stereo = render()
        let start = Int(2.0 * sampleRate)
        let end = Int(5.6 * sampleRate)
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
        #expect(sideEnergy > midEnergy * 0.15, "spacious diffused stereo spread")
        #expect(midEnergy > sideEnergy, "mono-compatible centre image (mid > side)")
    }

    @Test func `cancelling early fades out smoothly to silence without a click`() {
        var score = WelcomeOpeningScore(sampleRate: sampleRate)
        let cutFrame = Int(3.2 * sampleRate)
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
