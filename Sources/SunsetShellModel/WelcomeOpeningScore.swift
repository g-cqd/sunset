import Foundation

/// Procedural stereo synthesizer for the welcome opening's score (`WelcomeOpening`): a unified, warm consonant blend
/// of low-mid bass (`55 / 73.4 Hz`), bowed electronic strings, softly sustained felted piano, and an airy flute in
/// open D-add9 (no semitone dissonances). Core bass and lower strings reach full bloom early as the sun forms, then
/// lift off cleanly into a weightless diffused reverb cloud that melts into silence across the window transition.
package struct WelcomeOpeningScore: Sendable {
    /// Total duration including the diffused reverb tail past `WelcomeOpening.duration`.
    package static let duration = WelcomeOpening.duration + 1.4
    private static let cancelFadeDuration = 0.42

    // Ultra-smooth chorus detuning (zero low-frequency pumping or harsh beating).
    private static let celloDetuneCents: [Double] = [-2.1, -0.7, 0.8, 2.2]
    private static let violaDetuneCents: [Double] = [-3.6, -1.2, 1.3, 3.8]
    private static let liftDetuneCents: [Double] = [-4.6, -1.5, 1.6, 4.8]
    private static let voicePans: [Double] = [-0.84, -0.36, 0.38, 0.86]
    private static let driftRates: [Double] = [0.06, 0.09, 0.11, 0.07, 0.13, 0.05]

    private let sampleRate: Double
    private let invSampleRate: Double
    private var frame = 0
    private var cancelStartFrame: Int?

    // Warm, tight bass stack centered at A1 (55 Hz) + D2 (73.42 Hz) + D3 warmth — full and rich without sub-40 Hz mud.
    private var bassFifthPhase = 0.0
    private var bassRootPhase = 0.0
    private var bassOctavePhase = 0.25
    private var celloPhases = [0.0, 0.25, 0.50, 0.75]
    private var violaPhases = [0.125, 0.375, 0.625, 0.875]
    private var liftPhases = [0.08, 0.33, 0.58, 0.83]
    private var driftPhases = [0.0, 0.19, 0.41, 0.67, 0.83, 0.52]

    private var piano = FeltPianoLayer()
    private var flute = AiryFluteLayer()
    private var filter = StereoFilter()
    private var reverb: DiffusedHall
    private var guardL: SubsonicGuard
    private var guardR: SubsonicGuard

    package init(sampleRate: Double = 48_000) {
        self.sampleRate = max(sampleRate, 8_000)
        self.invSampleRate = 1.0 / self.sampleRate
        self.reverb = DiffusedHall(sampleRate: self.sampleRate)
        self.guardL = SubsonicGuard(cutoffHz: 46.0, sampleRate: self.sampleRate)
        self.guardR = SubsonicGuard(cutoffHz: 46.0, sampleRate: self.sampleRate)
    }

    /// True once the score (or an early fade-out) has completed and will only produce silence.
    package var isFinished: Bool {
        if let cancelStartFrame {
            return Double(frame - cancelStartFrame) * invSampleRate >= Self.cancelFadeDuration
        }
        return Double(frame) * invSampleRate >= Self.duration
    }

    /// Begins a smooth fade-out from the current sample (used when the user cuts the opening short).
    package mutating func fadeOut() {
        guard cancelStartFrame == nil else { return }
        cancelStartFrame = frame
    }

    /// Produces the next stereo frame `(left, right)` in `[-1, 1]`.
    package mutating func nextSample() -> (left: Float, right: Float) {
        let currentFrame = frame
        let time = Double(currentFrame) * invSampleRate
        frame += 1

        let cancelGain = cancelEnvelope(atFrame: currentFrame)
        guard time < Self.duration, cancelGain > 0 else { return (0, 0) }

        let shape = PhaseShape.at(time)
        let (strL, strR) = synthesizeStrings(shape: shape)
        let (pianoL, pianoR) = piano.sample(at: time, invSampleRate: invSampleRate)
        let (fluteL, fluteR) = flute.sample(at: time, invSampleRate: invSampleRate)
        let busL = strL + pianoL * 0.82 + fluteL * 0.78
        let busR = strR + pianoR * 0.82 + fluteR * 0.78

        let (filtL, filtR) = filter.process(
            left: busL,
            right: busR,
            cutoffHz: shape.cutoffHz,
            resonance: shape.resonance,
            sampleRate: sampleRate,
            invSampleRate: invSampleRate
        )
        let (liftL, liftR) = synthesizeLiftOffHalo(bloom: shape.liftOffLevel)
        let sendL = filtL + pianoL * 0.24 + fluteL * 0.28 + liftL * 0.92
        let sendR = filtR + pianoR * 0.24 + fluteR * 0.28 + liftR * 0.92
        let (wetL, wetR) = reverb.process(
            left: sendL,
            right: sendR,
            feedback: shape.reverbFeedback,
            damp: shape.reverbDamp
        )

        let bass = synthesizeWarmBass(shape: shape)
        let gain = shape.master * cancelGain * 0.68
        let rawL = (bass + filtL * shape.dryMix + liftL * 0.16 + wetL * shape.wetMix) * gain
        let rawR = (bass + filtR * shape.dryMix + liftR * 0.16 + wetR * shape.wetMix) * gain
        let outL = guardL.process(rawL)
        let outR = guardR.process(rawR)
        return (Float(min(max(outL, -0.95), 0.95)), Float(min(max(outR, -0.95), 0.95)))
    }

    private func cancelEnvelope(atFrame currentFrame: Int) -> Double {
        guard let cancelStartFrame else { return 1.0 }
        let elapsed = Double(currentFrame - cancelStartFrame) * invSampleRate
        guard elapsed < Self.cancelFadeDuration else { return 0.0 }
        return 0.5 * (1.0 + cos(.pi * max(0.0, elapsed / Self.cancelFadeDuration)))
    }

    /// Warm, musical bass centered on D2 (73.42 Hz) with gentle A1 (55 Hz) undertone and D3 harmonic — full on laptop
    /// speakers and headphones alike, without sub-40 Hz mud.
    private mutating func synthesizeWarmBass(shape: PhaseShape) -> Double {
        bassFifthPhase = Self.advance(bassFifthPhase, hz: 55.000, invRate: invSampleRate)
        bassRootPhase = Self.advance(bassRootPhase, hz: 73.416, invRate: invSampleRate)
        bassOctavePhase = Self.advance(bassOctavePhase, hz: 146.832, invRate: invSampleRate)
        let a1 = 0.26 * sin(2.0 * .pi * bassFifthPhase)
        let d2 = 0.72 * sin(2.0 * .pi * bassRootPhase)
        let d3 = 0.24 * sin(2.0 * .pi * bassOctavePhase)
        return (a1 + d2 + d3) * 0.36 * shape.warmBassLevel
    }

    private mutating func synthesizeStrings(shape: PhaseShape) -> (Double, Double) {
        for idx in 0 ..< driftPhases.count {
            driftPhases[idx] = Self.advance(driftPhases[idx], hz: Self.driftRates[idx], invRate: invSampleRate)
        }
        let pitchDrift = 1.0 + 0.0007 * sin(2.0 * .pi * driftPhases[1])
        var left = 0.0
        var right = 0.0

        let (celloL, celloR) = Self.stepChorus(
            phases: &celloPhases,
            drift: driftPhases,
            spec: ChorusSpec(
                baseHz: 110.0 * pitchDrift,
                detuneCents: Self.celloDetuneCents,
                gain: 0.23 * shape.stringLevel,
                invertPan: false
            ),
            invRate: invSampleRate
        )
        let (violaL, violaR) = Self.stepChorus(
            phases: &violaPhases,
            drift: driftPhases,
            spec: ChorusSpec(
                baseHz: 146.832 * pitchDrift,
                detuneCents: Self.violaDetuneCents,
                gain: 0.19 * shape.stringLevel,
                invertPan: true
            ),
            invRate: invSampleRate
        )
        left += celloL + violaL
        right += celloR + violaR
        return (left, right)
    }

    private struct ChorusSpec {
        let baseHz: Double
        let detuneCents: [Double]
        let gain: Double
        let invertPan: Bool
    }

    private static func stepChorus(
        phases: inout [Double],
        drift: [Double],
        spec: ChorusSpec,
        invRate: Double
    ) -> (Double, Double) {
        var left = 0.0
        var right = 0.0
        for idx in 0 ..< phases.count {
            let vib = 1.0 + 0.0005 * sin(2.0 * .pi * drift[(idx + 2) % drift.count])
            let hz = spec.baseHz * pow(2.0, spec.detuneCents[idx] / 1200.0) * vib
            phases[idx] = advance(phases[idx], hz: hz, invRate: invRate)
            let pan = spec.invertPan ? -voicePans[idx] : voicePans[idx]
            accumulate(bowedSaw(phases[idx]) * spec.gain, pan: pan, left: &left, right: &right)
        }
        return (left, right)
    }

    /// Weightless upward lift-off string halo (`D4, E4, F#4, A4`) sent mostly into the diffused hall as the bass
    /// recedes, creating the sensation of floating into light as the window appears.
    private mutating func synthesizeLiftOffHalo(bloom: Double) -> (Double, Double) {
        guard bloom > 1e-6 else { return (0, 0) }
        let notes = [293.665, 329.628, 369.994, 440.000]
        let pitchDrift = 1.0 + 0.0008 * sin(2.0 * .pi * driftPhases[0])
        let gain = 0.135 * bloom
        var left = 0.0
        var right = 0.0
        for idx in 0 ..< liftPhases.count {
            let hz = notes[idx] * pow(2.0, Self.liftDetuneCents[idx] / 1200.0) * pitchDrift
            liftPhases[idx] = Self.advance(liftPhases[idx], hz: hz, invRate: invSampleRate)
            let sample = (0.32 * Self.bowedSaw(liftPhases[idx]) + 0.68 * sin(2.0 * .pi * liftPhases[idx])) * gain
            Self.accumulate(sample, pan: Self.voicePans[idx], left: &left, right: &right)
        }
        return (left, right)
    }
}
