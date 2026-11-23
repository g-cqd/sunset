import Foundation

extension WelcomeOpeningScore {
    /// A single sustained, softly bloomed felted-piano resonance: zero hammer bump, warm string character, and
    /// cohesive sustained decay.
    struct FeltPianoVoice: Sendable {
        let baseHz: Double
        let amplitude: Double
        let pan: Double
        let envelope: Envelope
        private var p1: Double
        private var p2: Double
        private var p3: Double

        init(baseHz: Double, amplitude: Double, pan: Double, envelope: Envelope, seed: Double) {
            self.baseHz = baseHz
            self.amplitude = amplitude
            self.pan = pan
            self.envelope = envelope
            self.p1 = seed
            self.p2 = (seed + 0.43).truncatingRemainder(dividingBy: 1.0)
            self.p3 = (seed + 0.77).truncatingRemainder(dividingBy: 1.0)
        }

        mutating func sample(at time: Double, invSampleRate: Double) -> (Double, Double) {
            let leave = envelope.leaving(at: time)
            let env = envelope.level(at: time)
            guard env > 1e-6 else { return (0, 0) }

            let b = 0.00032
            p1 = ScoreMath.advance(p1, hz: baseHz, invSampleRate: invSampleRate)
            p2 = ScoreMath.advance(p2, hz: baseHz * 2.0 * sqrt(1.0 + 4.0 * b), invSampleRate: invSampleRate)
            p3 = ScoreMath.advance(p3, hz: baseHz * 3.0 * sqrt(1.0 + 9.0 * b), invSampleRate: invSampleRate)

            let shimmer = 0.35 + 0.65 * leave
            let body =
                0.70 * sin(2.0 * .pi * p1)
                + 0.22 * sin(2.0 * .pi * p2) * shimmer
                + 0.06 * sin(2.0 * .pi * p3) * shimmer * shimmer

            let value = body * env * amplitude
            let angle = (pan + 1.0) * 0.25 * .pi
            return (value * cos(angle), value * sin(angle))
        }
    }

    /// Pure consonant D-add9 sustained felted-piano harmony (no half-step clashes): core voices (`D3, F♯3, A3`)
    /// bloom early (~1.8 s), then open upper tones (`E4, F♯4, A4`) lift off cleanly into the diffused reverb cloud.
    struct FeltPianoLayer: Sendable {
        /// Each voice: its pitch (Hz), loudness, place (-1 left … 1 right), entry (start, length), leaving (start, length)
        /// and phase seed.
        private static let table: [[Double]] = [
            // Early-blooming warm D major triad (D3, F#3, A3) — open, serene, zero semitone clash.
            [146.832, 0.16, -0.26, 0.0, 1.75, 2.6, 3.2, 0.11],
            [184.997, 0.14, -0.46, 0.08, 1.85, 3.1, 3.3, 0.59],
            [220.000, 0.15, 0.28, 0.0, 1.80, 2.8, 3.3, 0.37],
            // Lift-off halo: open D4, E4, F#4, and A4 float upward as the bass releases into diffusion.
            [293.665, 0.10, -0.22, 1.30, 1.80, 4.0, 3.2, 0.23],
            [329.628, 0.105, 0.52, 1.55, 1.85, 4.1, 3.2, 0.83],
            [369.994, 0.085, -0.64, 2.15, 1.95, 4.4, 3.1, 0.47],
            [440.000, 0.075, 0.66, 2.45, 2.00, 4.6, 3.1, 0.71]
        ]

        private var voices = table.map { v in
            FeltPianoVoice(
                baseHz: v[0],
                amplitude: v[1],
                pan: v[2],
                envelope: Envelope(enterStart: v[3], enterLength: v[4], leaveStart: v[5], leaveLength: v[6]),
                seed: v[7]
            )
        }

        mutating func sample(at time: Double, invSampleRate: Double) -> (Double, Double) {
            var left = 0.0
            var right = 0.0
            for idx in 0 ..< voices.count {
                let (l, r) = voices[idx].sample(at: time, invSampleRate: invSampleRate)
                left += l
                right += r
            }
            return (left, right)
        }
    }

    /// Warm, airy consonant flute: enters gently on luminous `F♯3` (185 Hz — in pure harmony with D major) and
    /// gracefully lifts upward via `E4 → F♯4` (whole step, no semitone clash) into the diffused reverb cloud.
    struct AiryFluteLayer: Sendable {
        private static let main = Envelope(enterStart: 0.10, enterLength: 1.75, leaveStart: 3.30, leaveLength: 3.40)
        private static let lift = Envelope(enterStart: 2.05, enterLength: 1.85, leaveStart: 4.45, leaveLength: 3.15)
        private var mainPhase = 0.17
        private var harmonicPhase = 0.43
        private var liftPhase = 0.71
        private var driftPhase = 0.09
        private var breathPhaseA = 0.23
        private var breathPhaseB = 0.61

        mutating func sample(at time: Double, invSampleRate: Double) -> (Double, Double) {
            let env = Self.main.level(at: time)

            // Pure consonant lift from warm E3 (164.81 Hz) up a whole step to radiant F#3 (185.0 Hz).
            let glide = ScoreMath.smooth((time - 1.50) / 1.80)
            let baseHz = 164.814 + (184.997 - 164.814) * glide

            driftPhase = ScoreMath.advance(driftPhase, hz: 0.34, invSampleRate: invSampleRate)
            let vib = 1.0 + 0.0012 * sin(2.0 * .pi * driftPhase)
            let hz = baseHz * vib

            mainPhase = ScoreMath.advance(mainPhase, hz: hz, invSampleRate: invSampleRate)
            harmonicPhase = ScoreMath.advance(harmonicPhase, hz: hz * 2.0, invSampleRate: invSampleRate)

            // Upward lift-off voice: floats smoothly from E4 (329.63 Hz) up to F#4 (369.99 Hz) inside the diffusion.
            let liftEnv = Self.lift.level(at: time)
            let liftGlide = ScoreMath.smooth((time - 2.85) / 2.20)
            let liftHz = (329.628 + (369.994 - 329.628) * liftGlide) * vib
            liftPhase = ScoreMath.advance(liftPhase, hz: liftHz, invSampleRate: invSampleRate)

            guard env > 1e-6 || liftEnv > 1e-6 else { return (0, 0) }

            let fluteCore =
                0.76 * sin(2.0 * .pi * mainPhase)
                + 0.19 * sin(2.0 * .pi * harmonicPhase)
                + 0.04 * sin(6.0 * .pi * mainPhase)

            // Pure harmonic breath halo (octave + fifth, no inharmonic roughness).
            breathPhaseA = ScoreMath.advance(breathPhaseA, hz: hz * 1.500, invSampleRate: invSampleRate)
            breathPhaseB = ScoreMath.advance(breathPhaseB, hz: hz * 2.000, invSampleRate: invSampleRate)
            let breath = 0.020 * (sin(2.0 * .pi * breathPhaseA) + 0.5 * sin(2.0 * .pi * breathPhaseB))

            let mainSample = (fluteCore + breath) * 0.13 * env
            let liftSample = (0.82 * sin(2.0 * .pi * liftPhase) + 0.18 * sin(4.0 * .pi * liftPhase)) * 0.10 * liftEnv
            return (mainSample * 0.76 + liftSample * 0.42, mainSample * 0.62 + liftSample * 0.88)
        }
    }
}
