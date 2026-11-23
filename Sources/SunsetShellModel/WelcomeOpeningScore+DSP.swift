import Foundation

extension WelcomeOpeningScore {
    static func advance(_ phase: Double, hz: Double, invRate: Double) -> Double {
        let next = phase + hz * invRate
        return next - floor(next)
    }

    static func bowedSaw(_ phase: Double) -> Double {
        let saw = 2.0 * phase - 1.0
        return 0.50 * (saw - 0.36 * saw * saw * saw) + 0.50 * sin(2.0 * .pi * phase)
    }

    static func accumulate(_ sample: Double, pan: Double, left: inout Double, right: inout Double) {
        let angle = (pan + 1.0) * 0.25 * .pi
        left += sample * cos(angle)
        right += sample * sin(angle)
    }

    /// Control curves aligned with `WelcomeOpening`:
    /// - Warm bass (`55 / 73.4 Hz`, nothing sub-sonic) and core strings reach full bloom early (~1.8–2.5 s).
    /// - As the sun descends (`2.5–5.0 s`), the bass lifts away while upper strings, felt piano, and airy flute
    ///   float upward into a wide, silky diffused reverb cloud.
    /// - Across the window transition (`5.0–8.4 s`), the luminous cloud dissolves cleanly into silence.
    struct PhaseShape: Sendable {
        var warmBassLevel: Double
        var stringLevel: Double
        var liftOffLevel: Double
        var cutoffHz: Double
        var resonance: Double
        var dryMix: Double
        var wetMix: Double
        var reverbFeedback: Double
        var reverbDamp: Double
        var master: Double

        static func at(_ time: Double) -> Self {
            let earlyRise = smooth(clamp(time / 1.90))
            let groundRelease = 1.0 - smooth(clamp((time - 2.30) / 3.00))
            let stringRecede = 1.0 - smooth(clamp((time - 2.70) / 3.90))

            let liftRise = smooth(clamp((time - 1.85) / 2.20))
            let liftRelease = 1.0 - smooth(clamp((time - 4.40) / 3.30))
            let liftOff = liftRise * liftRelease

            let diffuseProgress = smooth(clamp((time - 2.40) / 3.30))
            let dryFade = 1.0 - smooth(clamp((time - 3.25) / 3.35))
            let tailFade = 1.0 - smooth(clamp((time - 6.00) / (WelcomeOpeningScore.duration - 6.00)))
            let onset = smooth(clamp(time / 0.70))

            let cutoff = 280.0 + 900.0 * (earlyRise * (0.25 + 0.75 * stringRecede)) + 540.0 * liftOff

            return Self(
                warmBassLevel: earlyRise * (0.14 + 0.86 * groundRelease),
                stringLevel: earlyRise * (0.18 + 0.82 * stringRecede) * dryFade,
                liftOffLevel: liftOff,
                cutoffHz: cutoff,
                resonance: 0.90 - 0.12 * earlyRise * stringRecede,
                dryMix: 0.60 * dryFade,
                wetMix: 0.34 + 0.44 * diffuseProgress,
                reverbFeedback: 0.69 + 0.14 * diffuseProgress,
                reverbDamp: 0.58 - 0.30 * smooth(clamp((time - 4.80) / 3.80)),
                master: onset * tailFade
            )
        }

        private static func smooth(_ value: Double) -> Double {
            let x = clamp(value)
            return x * x * x * (x * (6 * x - 15) + 10)
        }

        private static func clamp(_ value: Double) -> Double {
            min(max(value, 0), 1)
        }
    }

    /// 2nd-order Butterworth biquad high-pass filter (12 dB/octave).
    struct BiquadHighPass: Sendable {
        private let b0: Double
        private let b1: Double
        private let b2: Double
        private let a1: Double
        private let a2: Double
        private var z1 = 0.0
        private var z2 = 0.0

        init(cutoffHz: Double, sampleRate: Double) {
            let omega = 2.0 * .pi * cutoffHz / sampleRate
            let cosW = cos(omega)
            let alpha = sin(omega) / sqrt(2.0)
            let a0 = 1.0 + alpha
            b0 = ((1.0 + cosW) * 0.5) / a0
            b1 = -(1.0 + cosW) / a0
            b2 = ((1.0 + cosW) * 0.5) / a0
            a1 = (-2.0 * cosW) / a0
            a2 = (1.0 - alpha) / a0
        }

        mutating func process(_ input: Double) -> Double {
            let out = b0 * input + z1
            z1 = b1 * input - a1 * out + z2
            z2 = b2 * input - a2 * out
            return out
        }
    }

    /// 4th-order Butterworth high-pass filter (24 dB/octave at 46 Hz) — keeps warm 55 / 73.4 Hz bass full and tight
    /// while eliminating sub-bass rumble and guaranteeing nothing below 20 Hz.
    struct SubsonicGuard: Sendable {
        private var stage1: BiquadHighPass
        private var stage2: BiquadHighPass

        init(cutoffHz: Double = 46.0, sampleRate: Double) {
            stage1 = BiquadHighPass(cutoffHz: cutoffHz, sampleRate: sampleRate)
            stage2 = BiquadHighPass(cutoffHz: cutoffHz, sampleRate: sampleRate)
        }

        mutating func process(_ input: Double) -> Double {
            stage2.process(stage1.process(input))
        }
    }

    /// Stereo warm state-variable low-pass filter with a silky second stage.
    struct StereoFilter: Sendable {
        private var lpL = 0.0
        private var bpL = 0.0
        private var lpR = 0.0
        private var bpR = 0.0
        private var smoothL = 0.0
        private var smoothR = 0.0

        mutating func process(
            left: Double,
            right: Double,
            cutoffHz: Double,
            resonance: Double,
            sampleRate: Double,
            invSampleRate: Double
        ) -> (Double, Double) {
            let f = min(0.45, 2.0 * sin(.pi * min(cutoffHz, sampleRate * 0.2) * invSampleRate))
            let q = max(0.55, min(1.4, resonance))

            let hpL = left - lpL - q * bpL
            bpL += f * hpL
            lpL += f * bpL

            let hpR = right - lpR - q * bpR
            bpR += f * hpR
            lpR += f * bpR

            let alpha = min(0.95, 1.0 - exp(-2.0 * .pi * min(cutoffHz * 2.1, sampleRate * 0.25) * invSampleRate))
            smoothL += alpha * (lpL - smoothL)
            smoothR += alpha * (lpR - smoothR)
            return (smoothL, smoothR)
        }
    }
}
