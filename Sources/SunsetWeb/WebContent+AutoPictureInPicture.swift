import SunsetRuntime
import SunsetWebModel

/// A playing video floats when its page is left, and comes back when it is shown (`web.autoPictureInPicture`, n124).
extension WebContent {
    func followPictureInPicture(was: Bool, now: Bool) {
        guard let view = webView else { return }
        let card = nowPlaying.stack.pages.first { $0.id == mediaID }
        let change = AutoPictureInPicture.change(
            was: was,
            now: now,
            enabled: settings.autoPictureInPicture && settings.pictureInPicture,
            playsVideo: card.map { $0.hasVideo && $0.isPlaying } ?? false,
            floatedBySunset: floatedBySunset
        )
        let frame = videoFrame
        switch change {
            case .float:
                floatedBySunset = true
                runtime.task { @MainActor in await MediaReading.pictureInPicture(view, in: frame) }
            case .bringBack:
                floatedBySunset = false
                runtime.task { @MainActor in await MediaReading.inline(view, in: frame) }
            case nil:
                return
        }
    }
}
