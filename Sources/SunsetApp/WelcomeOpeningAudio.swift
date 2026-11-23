import AVFAudio
import Foundation
import SunsetRuntime
import SunsetShellModel
import Synchronization

/// Streams `WelcomeOpeningScore` through `AVAudioEngine` alongside the welcome opening (`WelcomeOpeningPlayer`).
/// Tears the engine down automatically once the diffused tail (or an early cancel fade-out) finishes so no audio
/// hardware stays active after the opening.
@MainActor enum WelcomeOpeningAudio {
    private static var active: Session?

    /// Starts playing the opening score from silence. Replaces any session still fading out.
    static func play() {
        stopImmediately()
        guard let session = Session.start() else { return }
        active = session
        scheduleCleanup(for: session, after: WelcomeOpeningScore.duration + 0.15)
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

    private final class Session: Sendable {
        private let engine: AVAudioEngine
        private let state: Mutex<WelcomeOpeningScore>

        private init(engine: AVAudioEngine, score: WelcomeOpeningScore) {
            self.engine = engine
            self.state = Mutex(score)
        }

        static func start() -> Session? {
            let engine = AVAudioEngine()
            let outputFormat = engine.outputNode.outputFormat(forBus: 0)
            let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48_000
            guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2) else { return nil }
            let session = Session(engine: engine, score: WelcomeOpeningScore(sampleRate: rate))
            let source = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
                session.render(audioBufferList, frames: Int(frameCount))
                return noErr
            }
            engine.attach(source)
            engine.connect(source, to: engine.mainMixerNode, format: format)
            do {
                try engine.start()
            } catch {
                engine.stop()
                return nil
            }
            return session
        }

        func fadeOut() {
            state.withLock { $0.fadeOut() }
        }

        func stop() {
            engine.stop()
        }

        private nonisolated func render(
            _ audioBufferList: UnsafeMutablePointer<AudioBufferList>,
            frames: Int
        ) {
            state.withLock { score in
                // CoreAudio provides two non-interleaved Float32 channel buffers sized for `frames` samples;
                // we write sequentially within `[0, frames)`.
                unsafe Self.fill(audioBufferList, frames: frames, score: &score)
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
}
