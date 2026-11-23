import Foundation

extension WelcomeOpeningScore {
    /// A single sustained, softly bloomed felted-piano resonance: zero hammer bump, warm string character, and
    /// cohesive sustained decay.
    struct FeltPianoVoice: Sendable {
        let baseHz: Double
        let amplitude: Double
        let pan: Double
        let enterStart: Double
        let enterLength: Double
        let leaveStart: Double
        let leaveLength: Double
        private var p1: Double
        private var p2: Double
        private var p3: Double

        init(
            baseHz: Double,
            amplitude: Double,
            pan: Double,
            enterStart: Double,
            enterLength: Double,
            leaveStart: Double,
            leaveLength: Double,
            seed: Double
        ) {
            self.baseHz = baseHz
            self.amplitude = amplitude
            self.pan = pan
            self.enterStart = enterStart
            self.enterLength = enterLength
            self.leaveStart = leaveStart
            self.leaveLength = leaveLength
            self.p1 = seed
            self.p2 = (seed + 0.43).truncatingRemainder(dividingBy: 1.0)
            self.p3 = (seed + 0.77).truncatingRemainder(dividingBy: 1.0)
        }

        mutating func sample(at time: Double, invSampleRate: Double) -> (Double, Double) {
            let enter = smooth((time - enterStart) / enterLength)
            let leave = 1.0 - smooth((time - leaveStart) / leaveLength)
            let env = enter * leave
            guard env > 1e-6 else { return (0, 0) }

            let b = 0.00032
            p1 = advance(p1, hz: baseHz, invSampleRate: invSampleRate)
            p2 = advance(p2, hz: baseHz * 2.0 * sqrt(1.0 + 4.0 * b), invSampleRate: invSampleRate)
            p3 = advance(p3, hz: baseHz * 3.0 * sqrt(1.0 + 9.0 * b), invSampleRate: invSampleRate)

            let shimmer = 0.35 + 0.65 * leave
            let body =
                0.70 * sin(2.0 * .pi * p1)
                + 0.22 * sin(2.0 * .pi * p2) * shimmer
                + 0.06 * sin(2.0 * .pi * p3) * shimmer * shimmer

            let value = body * env * amplitude
            let angle = (pan + 1.0) * 0.25 * .pi
            return (value * cos(angle), value * sin(angle))
        }

        private func advance(_ phase: Double, hz: Double, invSampleRate: Double) -> Double {
            let next = phase + hz * invSampleRate
            return next - floor(next)
        }

        private func smooth(_ value: Double) -> Double {
            let x = min(max(value, 0), 1)
            return x * x * x * (x * (6 * x - 15) + 10)
        }
    }

    /// Pure consonant D-add9 sustained felted-piano harmony (no half-step clashes): core voices (`D3, F♯3, A3`)
    /// bloom early (~1.8 s), then open upper tones (`E4, F♯4, A4`) lift off cleanly into the diffused reverb cloud.
    struct FeltPianoLayer: Sendable {
        private var voices: [FeltPianoVoice] = [
            // Early-blooming warm D major triad (D3, F#3, A3) — open, serene, zero semitone clash.
            FeltPianoVoice(
                baseHz: 146.832,
                amplitude: 0.16,
                pan: -0.26,
                enterStart: 0.0,
                enterLength: 1.75,
                leaveStart: 2.6,
                leaveLength: 3.2,
                seed: 0.11
            ),
            FeltPianoVoice(
                baseHz: 184.997,
                amplitude: 0.14,
                pan: -0.46,
                enterStart: 0.08,
                enterLength: 1.85,
                leaveStart: 3.1,
                leaveLength: 3.3,
                seed: 0.59
            ),
            FeltPianoVoice(
                baseHz: 220.000,
                amplitude: 0.15,
                pan: 0.28,
                enterStart: 0.0,
                enterLength: 1.80,
                leaveStart: 2.8,
                leaveLength: 3.3,
                seed: 0.37
            ),
            // Lift-off halo: open D4, E4, F#4, and A4 float upward as the bass releases into diffusion.
            FeltPianoVoice(
                baseHz: 293.665,
                amplitude: 0.10,
                pan: -0.22,
                enterStart: 1.30,
                enterLength: 1.80,
                leaveStart: 4.0,
                leaveLength: 3.2,
                seed: 0.23
            ),
            FeltPianoVoice(
                baseHz: 329.628,
                amplitude: 0.105,
                pan: 0.52,
                enterStart: 1.55,
                enterLength: 1.85,
                leaveStart: 4.1,
                leaveLength: 3.2,
                seed: 0.83
            ),
            FeltPianoVoice(
                baseHz: 369.994,
                amplitude: 0.085,
                pan: -0.64,
                enterStart: 2.15,
                enterLength: 1.95,
                leaveStart: 4.4,
                leaveLength: 3.1,
                seed: 0.47
            ),
            FeltPianoVoice(
                baseHz: 440.000,
                amplitude: 0.075,
                pan: 0.66,
                enterStart: 2.45,
                enterLength: 2.00,
                leaveStart: 4.6,
                leaveLength: 3.1,
                seed: 0.71
            )
        ]

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
        private var mainPhase = 0.17
        private var harmonicPhase = 0.43
        private var liftPhase = 0.71
        private var driftPhase = 0.09
        private var breathPhaseA = 0.23
        private var breathPhaseB = 0.61

        mutating func sample(at time: Double, invSampleRate: Double) -> (Double, Double) {
            let enter = smooth((time - 0.10) / 1.75)
            let leave = 1.0 - smooth((time - 3.30) / 3.40)
            let env = enter * leave

            // Pure consonant lift from warm E3 (164.81 Hz) up a whole step to radiant F#3 (185.0 Hz).
            let glide = smooth((time - 1.50) / 1.80)
            let baseHz = 164.814 + (184.997 - 164.814) * glide

            driftPhase = advance(driftPhase, hz: 0.34, invSampleRate: invSampleRate)
            let vib = 1.0 + 0.0012 * sin(2.0 * .pi * driftPhase)
            let hz = baseHz * vib

            mainPhase = advance(mainPhase, hz: hz, invSampleRate: invSampleRate)
            harmonicPhase = advance(harmonicPhase, hz: hz * 2.0, invSampleRate: invSampleRate)

            // Upward lift-off voice: floats smoothly from E4 (329.63 Hz) up to F#4 (369.99 Hz) inside the diffusion.
            let liftIn = smooth((time - 2.05) / 1.85)
            let liftOut = 1.0 - smooth((time - 4.45) / 3.15)
            let liftEnv = liftIn * liftOut
            let liftGlide = smooth((time - 2.85) / 2.20)
            let liftHz = (329.628 + (369.994 - 329.628) * liftGlide) * vib
            liftPhase = advance(liftPhase, hz: liftHz, invSampleRate: invSampleRate)

            guard env > 1e-6 || liftEnv > 1e-6 else { return (0, 0) }

            let fluteCore =
                0.76 * sin(2.0 * .pi * mainPhase)
                + 0.19 * sin(2.0 * .pi * harmonicPhase)
                + 0.04 * sin(6.0 * .pi * mainPhase)

            // Pure harmonic breath halo (octave + fifth, no inharmonic roughness).
            breathPhaseA = advance(breathPhaseA, hz: hz * 1.500, invSampleRate: invSampleRate)
            breathPhaseB = advance(breathPhaseB, hz: hz * 2.000, invSampleRate: invSampleRate)
            let breath = 0.020 * (sin(2.0 * .pi * breathPhaseA) + 0.5 * sin(2.0 * .pi * breathPhaseB))

            let mainSample = (fluteCore + breath) * 0.13 * env
            let liftSample = (0.82 * sin(2.0 * .pi * liftPhase) + 0.18 * sin(4.0 * .pi * liftPhase)) * 0.10 * liftEnv
            return (mainSample * 0.76 + liftSample * 0.42, mainSample * 0.62 + liftSample * 0.88)
        }

        private func advance(_ phase: Double, hz: Double, invSampleRate: Double) -> Double {
            let next = phase + hz * invSampleRate
            return next - floor(next)
        }

        private func smooth(_ value: Double) -> Double {
            let x = min(max(value, 0), 1)
            return x * x * x * (x * (6 * x - 15) + 10)
        }
    }
}
