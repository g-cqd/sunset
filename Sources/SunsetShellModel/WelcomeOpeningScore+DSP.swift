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

    static func softTriSaw(_ phase: Double) -> Double {
        0.84 * (1.0 - 4.0 * abs(phase - 0.5)) + 0.16 * sin(4.0 * .pi * phase)
    }

    static func accumulate(_ sample: Double, pan: Double, left: inout Double, right: inout Double) {
        let angle = (pan + 1.0) * 0.25 * .pi
        left += sample * cos(angle)
        right += sample * sin(angle)
    }

    /// Control curves aligned with `WelcomeOpening`:
    /// - One smooth, bump-free rise peaking early (`2.5–3.2 s`) as the sun forms and begins setting.
    /// - Gentle, hopeful resolution as the window fades in (`5.0 s`), with no late volume surge.
    /// - Smooth dissolution of dry voices into a silky, diffused cloud that melts cleanly into silence.
    struct PhaseShape: Sendable {
        var bassLevel: Double
        var stringLevel: Double
        var shimmerDissonance: Double
        var resolveLevel: Double
        var cutoffHz: Double
        var resonance: Double
        var dryMix: Double
        var wetMix: Double
        var reverbFeedback: Double
        var reverbDamp: Double
        var master: Double

        static func at(_ time: Double) -> Self {
            // Single smooth onset rising to full bloom around 2.6 s.
            let onset = smooth(clamp(time / 2.60))
            // Early climax envelope: peaks ~2.6–3.1 s, then gently descends through the sun-set and window reveal.
            let afterPeak = 1.0 - smooth(clamp((time - 2.95) / 4.40))
            let climax = onset * (0.18 + 0.82 * afterPeak)

            // Window handoff progress (5.0..8.4 s): brings a subtle harmonic glow without raising overall loudness.
            let window = smooth(progress(time, WelcomeOpening.windowPhase))
            let windowGlow = sin(.pi * clamp(window))

            // Tender suspended dissonance peaks with the early climax and dissolves gently before the window settles.
            let suspensionOut = 1.0 - smooth(clamp((time - 2.80) / 2.50))
            let suspension = onset * suspensionOut

            // Dry instruments recede steadily after the climax so the ending becomes pure diffused light.
            let dryFade = 1.0 - smooth(clamp((time - 3.60) / 3.40))
            let tailFade = 1.0 - smooth(clamp((time - 5.80) / (WelcomeOpeningScore.duration - 5.80)))

            // Golden filter sweep: opens smoothly to ~1250 Hz at the early climax, softens steadily into the tail.
            let cutoff = 280.0 + 980.0 * pow(climax, 0.85) + 180.0 * windowGlow * dryFade

            // Reverb feedback stays steady/gentle so wet energy never balloons later in the curve.
            let wetProgress = smooth(clamp((time - 3.20) / 3.40))
            return Self(
                bassLevel: onset * (0.20 + 0.80 * climax) * (1.0 - 0.88 * window),
                stringLevel: onset * (0.18 + 0.82 * climax) * dryFade,
                shimmerDissonance: suspension * dryFade,
                resolveLevel: smooth(clamp((time - 2.20) / 1.80)) * (0.35 + 0.65 * afterPeak) * dryFade,
                cutoffHz: cutoff,
                resonance: 0.92 - 0.12 * climax,
                dryMix: 0.62 * dryFade,
                wetMix: 0.36 + 0.24 * wetProgress,
                reverbFeedback: 0.68 + 0.08 * wetProgress,
                reverbDamp: 0.56 - 0.26 * wetProgress,
                master: smooth(clamp(time / 0.90)) * tailFade
            )
        }

        private static func progress(_ time: Double, _ phase: (start: Double, length: Double)) -> Double {
            clamp((time - phase.start) / phase.length)
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

    /// 4th-order Butterworth high-pass filter (24 dB/octave) to guarantee virtually zero sub-20 Hz energy.
    struct SubsonicGuard: Sendable {
        private var stage1: BiquadHighPass
        private var stage2: BiquadHighPass

        init(cutoffHz: Double = 48.0, sampleRate: Double) {
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

    /// Single allpass diffuser line to smear transients into a seamless cloud.
    struct AllpassLine: Sendable {
        private var buffer: [Double]
        private var index = 0

        init(samples: Int) {
            buffer = [Double](repeating: 0, count: max(16, samples))
        }

        mutating func process(_ input: Double, gain: Double) -> Double {
            let delayed = buffer[index]
            let output = -gain * input + delayed
            buffer[index] = input + gain * delayed
            index = (index + 1) % buffer.count
            return output
        }
    }

    /// Dense, silky diffused hall: 4 short cascaded stereo allpass diffusers feeding a high-passed 4-line damped
    /// Hadamard FDN. High-passing inside the tank prevents any sub-20 Hz or low-frequency comb bumps.
    struct DiffusedHall: Sendable {
        private var diffL1: AllpassLine
        private var diffL2: AllpassLine
        private var diffL3: AllpassLine
        private var diffL4: AllpassLine
        private var diffR1: AllpassLine
        private var diffR2: AllpassLine
        private var diffR3: AllpassLine
        private var diffR4: AllpassLine
        private var delayA: [Double]
        private var delayB: [Double]
        private var delayC: [Double]
        private var delayD: [Double]
        private var idxA = 0
        private var idxB = 0
        private var idxC = 0
        private var idxD = 0
        private var dampA = 0.0
        private var dampB = 0.0
        private var dampC = 0.0
        private var dampD = 0.0
        private var hpA: BiquadHighPass
        private var hpB: BiquadHighPass
        private var hpC: BiquadHighPass
        private var hpD: BiquadHighPass

        init(sampleRate: Double) {
            diffL1 = AllpassLine(samples: Int((0.0047 * sampleRate).rounded()))
            diffL2 = AllpassLine(samples: Int((0.0091 * sampleRate).rounded()))
            diffL3 = AllpassLine(samples: Int((0.0157 * sampleRate).rounded()))
            diffL4 = AllpassLine(samples: Int((0.0233 * sampleRate).rounded()))
            diffR1 = AllpassLine(samples: Int((0.0053 * sampleRate).rounded()))
            diffR2 = AllpassLine(samples: Int((0.0103 * sampleRate).rounded()))
            diffR3 = AllpassLine(samples: Int((0.0173 * sampleRate).rounded()))
            diffR4 = AllpassLine(samples: Int((0.0257 * sampleRate).rounded()))
            // Tighter mutually prime tank delays (~29–73 ms) for smooth, bump-free onset and lush tail.
            delayA = [Double](repeating: 0, count: max(64, Int((0.0293 * sampleRate).rounded())))
            delayB = [Double](repeating: 0, count: max(64, Int((0.0419 * sampleRate).rounded())))
            delayC = [Double](repeating: 0, count: max(64, Int((0.0569 * sampleRate).rounded())))
            delayD = [Double](repeating: 0, count: max(64, Int((0.0733 * sampleRate).rounded())))
            hpA = BiquadHighPass(cutoffHz: 72.0, sampleRate: sampleRate)
            hpB = BiquadHighPass(cutoffHz: 72.0, sampleRate: sampleRate)
            hpC = BiquadHighPass(cutoffHz: 72.0, sampleRate: sampleRate)
            hpD = BiquadHighPass(cutoffHz: 72.0, sampleRate: sampleRate)
        }

        mutating func process(left: Double, right: Double, feedback: Double, damp: Double) -> (Double, Double) {
            let inL = diffL4.process(
                diffL3.process(diffL2.process(diffL1.process(left, gain: 0.56), gain: 0.54), gain: 0.50),
                gain: 0.46
            )
            let inR = diffR4.process(
                diffR3.process(diffR2.process(diffR1.process(right, gain: 0.56), gain: 0.54), gain: 0.50),
                gain: 0.46
            )

            dampA += damp * (hpA.process(delayA[idxA]) - dampA)
            dampB += damp * (hpB.process(delayB[idxB]) - dampB)
            dampC += damp * (hpC.process(delayC[idxC]) - dampC)
            dampD += damp * (hpD.process(delayD[idxD]) - dampD)

            let m0 = 0.5 * (dampA + dampB + dampC + dampD)
            let m1 = 0.5 * (dampA - dampB + dampC - dampD)
            let m2 = 0.5 * (dampA + dampB - dampC - dampD)
            let m3 = 0.5 * (dampA - dampB - dampC + dampD)

            delayA[idxA] = inL + m0 * feedback
            delayB[idxB] = inR + m1 * feedback
            delayC[idxC] = inL * 0.85 + inR * 0.15 + m2 * feedback
            delayD[idxD] = inR * 0.85 + inL * 0.15 + m3 * feedback

            idxA = (idxA + 1) % delayA.count
            idxB = (idxB + 1) % delayB.count
            idxC = (idxC + 1) % delayC.count
            idxD = (idxD + 1) % delayD.count

            return (0.50 * (dampA - dampC), 0.50 * (dampB - dampD))
        }
    }
}
