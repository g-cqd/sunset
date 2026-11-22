import Foundation

/// What a page's script posts to Sunset is handled for one page, held weakly: the page owns its web view, whose controller holds
/// the handler (`LinkHover`, `IconWatch`, `TextWatch`, `WebNotifications` and `ShareWrapper` each held it the same way).
@MainActor
class PageScriptHandler: NSObject {
    private(set) weak var content: WebContent?

    init(page: WebContent) {
        content = page
    }
}
