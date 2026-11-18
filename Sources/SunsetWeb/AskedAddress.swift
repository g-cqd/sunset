import Foundation
import WebKit

/// The address the person last asked a page for, and whether a script of the site has sent the page elsewhere since
/// (roadmap 0045 F). A site that does not like the browser it is shown sends it away with `location.replace` to a page
/// that never sends it back; when the site is then shown another browser, it is the address asked for that is loaded
/// again, not the page the site chose.
struct AskedAddress {
    private(set) var url: URL?
    private var movedByScript = false

    /// The person asked for `url`: typed, picked, opened by Sunset.
    mutating func asked(_ url: URL?) {
        self.url = url
        movedByScript = false
    }

    /// The main frame goes to `url`. A link, a form or the history is the person asking; a load that is not one of
    /// theirs and not what they asked is the page's own doing. Loading the page again asks nothing new.
    mutating func navigation(to url: URL?, type: WKNavigationType) {
        switch type {
            case .linkActivated, .formSubmitted, .formResubmitted, .backForward: asked(url)
            case .reload: break
            case .other: if url != self.url { movedByScript = true }
            @unknown default: break
        }
    }

    /// Where to go to show the site anew from `current`: the address asked for when a script of the same site sent the
    /// page away from it; nil when the page is to be loaded again where it is.
    func target(current: URL?) -> URL? {
        guard movedByScript, let url, let host = url.host(), let now = current?.host(),
            SiteHost.key(host) == SiteHost.key(now), url != current
        else { return nil }
        return url
    }
}
