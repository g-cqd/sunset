import Foundation

extension WelcomeOpeningScore {
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
    /// Hadamard FDN. High-passing inside the tank keeps the bass tight while upper harmonics float effortlessly.
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
            delayA = [Double](repeating: 0, count: max(64, Int((0.0311 * sampleRate).rounded())))
            delayB = [Double](repeating: 0, count: max(64, Int((0.0443 * sampleRate).rounded())))
            delayC = [Double](repeating: 0, count: max(64, Int((0.0607 * sampleRate).rounded())))
            delayD = [Double](repeating: 0, count: max(64, Int((0.0797 * sampleRate).rounded())))
            hpA = BiquadHighPass(cutoffHz: 110.0, sampleRate: sampleRate)
            hpB = BiquadHighPass(cutoffHz: 110.0, sampleRate: sampleRate)
            hpC = BiquadHighPass(cutoffHz: 110.0, sampleRate: sampleRate)
            hpD = BiquadHighPass(cutoffHz: 110.0, sampleRate: sampleRate)
        }

        mutating func process(left: Double, right: Double, feedback: Double, damp: Double) -> (Double, Double) {
            let inL = diffL4.process(
                diffL3.process(diffL2.process(diffL1.process(left, gain: 0.58), gain: 0.54), gain: 0.50),
                gain: 0.46
            )
            let inR = diffR4.process(
                diffR3.process(diffR2.process(diffR1.process(right, gain: 0.58), gain: 0.54), gain: 0.50),
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

            return (0.52 * (dampA - dampC), 0.52 * (dampB - dampD))
        }
    }
}
