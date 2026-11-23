import Foundation

extension WelcomeOpeningScore {
    /// A single sustained, softly bloomed felted-piano resonance: zero hammer bump, authentic warm string
    /// inharmonicity, and cohesive sustained decay.
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

            let b = 0.00036
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

    /// Unified sustained felted-piano harmony in radiant D major 9: swells together smoothly from the start into an
    /// early golden climax (`2.5–3.2 s`), with gentle `C♯4 / E4` major-7th/9th warmth that dissolves into the reverb.
    struct FeltPianoLayer: Sendable {
        private var voices: [FeltPianoVoice] = [
            // Unified warm D major 9 chord blooming right into the early climax.
            FeltPianoVoice(
                baseHz: 146.832,
                amplitude: 0.16,
                pan: -0.26,
                enterStart: 0.0,
                enterLength: 2.3,
                leaveStart: 3.4,
                leaveLength: 3.4,
                seed: 0.11
            ),
            FeltPianoVoice(
                baseHz: 220.000,
                amplitude: 0.14,
                pan: 0.28,
                enterStart: 0.0,
                enterLength: 2.35,
                leaveStart: 3.5,
                leaveLength: 3.4,
                seed: 0.37
            ),
            FeltPianoVoice(
                baseHz: 184.997,
                amplitude: 0.14,
                pan: -0.46,
                enterStart: 0.15,
                enterLength: 2.3,
                leaveStart: 3.7,
                leaveLength: 3.3,
                seed: 0.59
            ),
            FeltPianoVoice(
                baseHz: 329.628,
                amplitude: 0.10,
                pan: 0.50,
                enterStart: 0.25,
                enterLength: 2.3,
                leaveStart: 3.8,
                leaveLength: 3.3,
                seed: 0.83
            ),
            // Tender major-7th dissonance (C#4, 277.18 Hz) kissing D4 softly at the early climax before releasing.
            FeltPianoVoice(
                baseHz: 277.183,
                amplitude: 0.085,
                pan: -0.58,
                enterStart: 0.45,
                enterLength: 2.0,
                leaveStart: 2.9,
                leaveLength: 2.3,
                seed: 0.23
            ),
            // Luminous D4 octave halo blooming as C#4 resolves toward the window reveal.
            FeltPianoVoice(
                baseHz: 293.665,
                amplitude: 0.10,
                pan: 0.22,
                enterStart: 1.80,
                enterLength: 1.9,
                leaveStart: 4.1,
                leaveLength: 3.3,
                seed: 0.67
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

    /// Warm, airy flute fused into the harmonic cloud: swells cleanly into the early climax on a suspended `G3`
    /// (196 Hz), then glides smoothly down a semitone to luminous `F♯3` (185 Hz) as the sun hands off to the window,
    /// accompanied by a serene `A3` (220 Hz) fifth breeze.
    struct AiryFluteLayer: Sendable {
        private var mainPhase = 0.17
        private var harmonicPhase = 0.43
        private var haloPhase = 0.71
        private var driftPhase = 0.09
        private var breathPhaseA = 0.23
        private var breathPhaseB = 0.61

        mutating func sample(at time: Double, invSampleRate: Double) -> (Double, Double) {
            let enter = smooth((time - 0.20) / 2.20)
            let leave = 1.0 - smooth((time - 3.60) / 3.40)
            let env = enter * leave
            guard env > 1e-6 else { return (0, 0) }

            // Smooth 4-3 suspension glide G3 (196.0 Hz) -> F#3 (185.0 Hz) resolving gently toward the window.
            let glide = smooth((time - 2.90) / 1.90)
            let baseHz = 195.998 + (184.997 - 195.998) * glide

            driftPhase = advance(driftPhase, hz: 0.38, invSampleRate: invSampleRate)
            let hz = baseHz * (1.0 + 0.0014 * sin(2.0 * .pi * driftPhase))

            mainPhase = advance(mainPhase, hz: hz, invSampleRate: invSampleRate)
            harmonicPhase = advance(harmonicPhase, hz: hz * 2.0, invSampleRate: invSampleRate)

            let haloEnv = smooth((time - 2.30) / 1.80) * leave
            haloPhase = advance(
                haloPhase,
                hz: 220.0 * (1.0 + 0.0012 * sin(2.0 * .pi * driftPhase)),
                invSampleRate: invSampleRate
            )

            let fluteCore =
                0.76 * sin(2.0 * .pi * mainPhase)
                + 0.19 * sin(2.0 * .pi * harmonicPhase)
                + 0.04 * sin(6.0 * .pi * mainPhase)

            breathPhaseA = advance(breathPhaseA, hz: hz * 1.498, invSampleRate: invSampleRate)
            breathPhaseB = advance(breathPhaseB, hz: hz * 2.011, invSampleRate: invSampleRate)
            let breath = 0.024 * (sin(2.0 * .pi * breathPhaseA) + 0.5 * sin(2.0 * .pi * breathPhaseB))

            let mainSample = (fluteCore + breath) * 0.14 * env
            let haloSample = sin(2.0 * .pi * haloPhase) * 0.075 * haloEnv
            return (mainSample * 0.76 + haloSample * 0.42, mainSample * 0.62 + haloSample * 0.86)
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
