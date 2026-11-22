import SunsetRuntime

extension WebContent {
    /// Tells Now Playing what this page plays now (roadmap 0114): when it starts or stops playing sound, and when its
    /// title changes while it has a card (a playlist's next song).
    func reportMedia() {
        runtime.task { @MainActor [weak self] in
            guard let self else { return }
            await nowPlaying.report(self)
        }
    }
}
