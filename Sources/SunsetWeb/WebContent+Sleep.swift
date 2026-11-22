import Foundation
import WebKit

/// A page not on screen lets go of its view to free its memory: its address, its history and its place in it are kept
/// (`interactionState`), and its picture; shown again, it is made again there.
extension WebContent {
    /// Whether something would be lost or broken by unloading it now: it plays, captures, or holds a dialog or a question.
    package var mustStayLoaded: Bool {
        playsSound || captureMark != nil || dialog != nil || credentialRequest != nil
    }

    /// Lets the view go, when it is not on screen and nothing keeps it.
    /// - Returns: whether it was unloaded.
    @discardableResult
    package func unload() -> Bool {
        guard !shown, webView != nil, !mustStayLoaded else { return false }
        endView(keepingHistory: true)
        progress = nil
        // It loads no more: nothing is left saying it does.
        isLoading = false
        isUnloaded = true
        hiddenSince = nil
        return true
    }

    /// Whether the page holds text typed in a field and not sent: asked of the page before it is unloaded. Not perfect, said
    /// plainly: a field the page keeps itself, outside `value`, is not seen. False when the page cannot be asked.
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
