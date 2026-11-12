import WebKit

extension WebContent {
    /// Text typed into a field of the page and not sent (web step q): a field whose value is not empty and not the one it came with. Fields in
    /// frames of other sites are not seen. False when the page does not answer within half a second.
    package func hasUnsentForm() async -> Bool {
        guard let webView, url != nil else { return false }
        let script = """
            (() => { for (const e of document.querySelectorAll('textarea, input:not([type=hidden]):not([type=submit]):not([type=button]):not([type=checkbox]):not([type=radio]):not([type=password])')) {
              if (e.value.trim() !== '' && e.value !== e.defaultValue) return true }
              for (const e of document.querySelectorAll('[contenteditable=""], [contenteditable=true]')) { if (e.textContent.trim() !== '') return true }
              return false })()
            """
        return await withCheckedContinuation { continuation in
            var answered = false
            webView.evaluateJavaScript(script) { value, _ in
                MainActor.assumeIsolated {
                    guard !answered else { return }
                    answered = true
                    continuation.resume(returning: value as? Bool ?? false)
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !answered else { return }
                answered = true
                continuation.resume(returning: false)
            }
        }
    }
}
