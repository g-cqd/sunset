import AVFAudio
import Foundation
import SunsetRuntime
import SunsetShellModel
import Synchronization

/// Streams `WelcomeOpeningScore` through `AVAudioEngine` alongside the welcome opening (`WelcomeOpeningPlayer`).
/// Starts the engine and returns its presentation latency so the visual clock can lock onto the exact moment sound
/// reaches the speakers, and tears the engine down automatically once the diffused tail (or cancel fade-out) finishes.
@MainActor enum WelcomeOpeningAudio {
    private static var active: Session?

    /// Starts playing the opening score from silence. Replaces any session still fading out.
    /// - Returns: The audio output presentation latency in seconds so visuals can start in sync with the sound.
    @discardableResult
    static func play() -> TimeInterval {
        stopImmediately()
        guard let started = Session.start() else { return 0 }
        active = started.session
        scheduleCleanup(for: started.session, after: WelcomeOpeningScore.duration + started.latency + 0.15)
        return started.latency
    }

    /// Smoothly fades out the running score (used when the user cancels the opening or closes the welcome window).
    static func fadeOut() {
        guard let session = active else { return }
        session.fadeOut()
        scheduleCleanup(for: session, after: 0.55)
    }

    private static func stopImmediately() {
        active?.stop()
        active = nil
    }

    private static func scheduleCleanup(for session: Session, after delay: Double) {
        Runtime.live.task { @MainActor in
            await Runtime.live.sleep(for: .seconds(delay))
            guard active === session else { return }
            session.stop()
            active = nil
        }
    }

    /// Thread-safe handle to the score shared with CoreAudio's real-time render thread; keeps `AVAudioEngine` confined
    /// to `@MainActor` (the macOS 26.5 SDK does not mark `AVAudioEngine` as `Sendable`).
    private final class Renderer: Sendable {
        private let state: Mutex<WelcomeOpeningScore>

        init(score: WelcomeOpeningScore) {
            self.state = Mutex(score)
        }

        func fadeOut() {
            state.withLock { $0.fadeOut() }
        }

        /// Fills the buffers; true when the score has finished, and they hold silence.
        nonisolated func render(
            _ audioBufferList: UnsafeMutablePointer<AudioBufferList>,
            frames: Int
        ) -> Bool {
            state.withLock { score in
                // CoreAudio provides two non-interleaved Float32 channel buffers sized for `frames` samples;
                // we write sequentially within `[0, frames)`.
                unsafe Self.fill(audioBufferList, frames: frames, score: &score)
                return score.isFinished
            }
        }

        @unsafe
        private nonisolated static func fill(
            _ audioBufferList: UnsafeMutablePointer<AudioBufferList>,
            frames: Int,
            score: inout WelcomeOpeningScore
        ) {
            let buffers = unsafe UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard buffers.count >= 2,
                let left = unsafe buffers[0].mData?.assumingMemoryBound(to: Float.self),
                let right = unsafe buffers[1].mData?.assumingMemoryBound(to: Float.self)
            else { return }
            for index in 0 ..< frames {
                let sample = score.nextSample()
                unsafe left[index] = sample.left
                unsafe right[index] = sample.right
            }
        }
    }

    private final class Session {
        private let engine: AVAudioEngine
        private let renderer: Renderer

        private init(engine: AVAudioEngine, renderer: Renderer) {
            self.engine = engine
            self.renderer = renderer
        }

        static func start() -> (session: Session, latency: TimeInterval)? {
            let engine = AVAudioEngine()
            let outputNode = engine.outputNode
            let outputFormat = outputNode.outputFormat(forBus: 0)
            let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48_000
            guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2) else { return nil }
            let renderer = Renderer(score: WelcomeOpeningScore(sampleRate: rate))
            let session = Session(engine: engine, renderer: renderer)
            let source = AVAudioSourceNode(format: format) { isSilence, _, frameCount, audioBufferList in
                // Once the score has ended, its buffers are silence and CoreAudio is told so (it skips mixing them).
                if renderer.render(audioBufferList, frames: Int(frameCount)) { unsafe isSilence.pointee = true }
                return noErr
            }
            engine.attach(source)
            engine.connect(source, to: engine.mainMixerNode, format: format)
            engine.prepare()
            do {
                try engine.start()
            } catch {
                engine.stop()
                return nil
            }
            // Clamp latency to a sensible ceiling so a misreporting virtual device never stalls the opening.
            let latency = min(max(outputNode.presentationLatency, 0), 0.35)
            return (session, latency)
        }

        func fadeOut() {
            renderer.fadeOut()
        }

        func stop() {
            engine.stop()
        }
    }
}
