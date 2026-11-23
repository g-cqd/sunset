import Testing

@testable import SunsetWebModel

/// A playing video floats when its tab is left, and comes back when it is shown again (the owner's note n124): only with
/// the setting on and a video playing; only one Sunset floated comes back.
@Suite("Picture in picture when leaving a tab")
struct AutoPictureInPictureTests {
    @Test func `floats when left while a video plays, with the setting on`() {
        #expect(
            AutoPictureInPicture.change(was: true, now: false, enabled: true, playsVideo: true, floatedBySunset: false)
                == .float
        )
        #expect(
            AutoPictureInPicture.change(was: true, now: false, enabled: false, playsVideo: true, floatedBySunset: false)
                == nil
        )
        #expect(
            AutoPictureInPicture.change(was: true, now: false, enabled: true, playsVideo: false, floatedBySunset: false)
                == nil
        )
        #expect(
            AutoPictureInPicture.change(was: true, now: true, enabled: true, playsVideo: true, floatedBySunset: false)
                == nil
        )
    }

    @Test func `comes back when shown again, if Sunset floated it`() {
        #expect(
            AutoPictureInPicture.change(was: false, now: true, enabled: true, playsVideo: true, floatedBySunset: true)
                == .bringBack
        )
        #expect(
            AutoPictureInPicture.change(was: false, now: true, enabled: true, playsVideo: true, floatedBySunset: false)
                == nil
        )
        #expect(
            AutoPictureInPicture.change(was: false, now: false, enabled: true, playsVideo: true, floatedBySunset: true)
                == nil
        )
    }
}
