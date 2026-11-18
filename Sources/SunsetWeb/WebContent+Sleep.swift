import Foundation
import WebKit

/// A page not on screen lets go of its view to free its memory (roadmap 0021 S-f, ADR-0071): its address, its history and
/// its place in it are kept (`interactionState`), and its picture; shown again, it is made again there.
extension WebContent {
    /// Whether something would be lost or broken by unloading it now: it plays, captures, or holds a dialog or a question.
    package var mustStayLoaded: Bool {
        playsSound || captureDot != nil || dialog != nil || credentialRequest != nil
    }

    /// Lets the view go, when it is not on screen and nothing keeps it.
    /// - Returns: whether it was unloaded.
    @discardableResult
    package func unload() -> Bool {
        guard !shown, let view = webView, !mustStayLoaded else { return false }
        savedHistory = view.interactionState as? Data
        soundWatch = nil
        observations = []
        view.stopLoading()
        view.navigationDelegate = nil
        view.uiDelegate = nil
        view.removeFromSuperview()
        webView = nil
        coordinator = nil
        progress = nil
        isUnloaded = true
        hiddenSince = nil
        return true
    }

    /// Whether the page holds text typed in a field and not sent: asked of the page before it is unloaded. Not perfect, said
    /// plainly (R4): a field the page keeps itself, outside `value`, is not seen. False when the page cannot be asked.
    package func holdsUnsentText() async -> Bool {
        guard let webView else { return false }
        let script = """
            [...document.querySelectorAll('textarea, input:not([type]), input[type=text], input[type=search], \
            input[type=email], input[type=url]')].some(e => e.value !== e.defaultValue) \
            || [...document.querySelectorAll('[contenteditable=""], [contenteditable=true]')].some(e => e.textContent.trim().length > 0)
            """
        let result = try? await webView.evaluateJavaScript(script)
        return (result as? Bool) ?? false
    }
}
