/// When a page's video floats by itself (`web.autoPictureInPicture`, n124): it is left while its video plays, and the
/// setting allows it; it comes back when the page is shown again, if Sunset floated it (one the person floated stays).
package enum AutoPictureInPicture: Equatable {
    case float, bringBack

    /// What to do as the page goes from shown (`was`) to shown or not (`now`).
    package static func change(
        was: Bool,
        now: Bool,
        enabled: Bool,
        playsVideo: Bool,
        floatedBySunset: Bool
    ) -> Self? {
        if was, !now, enabled, playsVideo { return .float }
        if !was, now, floatedBySunset { return .bringBack }
        return nil
    }
}
