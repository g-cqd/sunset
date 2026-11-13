import Foundation

/// A page's dialogs (roadmap 0029 step 1): one at a time, in its pane; see `PageDialogPolicy`.
extension WebContent {
    /// Shows a dialog the page asked for and waits for its answer. A dialog asked while one waits, or by a silenced page, is
    /// answered as cancelled at once.
    func ask(_ kind: PageDialog.Kind, message: String, host: String) async -> PageDialog.Reply {
        guard dialog == nil, case .show(let offersSilence) = dialogPolicy.next() else { return .cancel }
        return await withCheckedContinuation { continuation in
            dialog = PageDialog(kind: kind, host: host, message: message, offersSilence: offersSilence) {
                [weak self] reply in
                self?.dialog = nil
                continuation.resume(returning: reply)
            }
        }
    }

    /// Asks for the name and password a server wants, one question at a time; nil when cancelled.
    func askCredential(host: String, realm: String, failed: Bool, secure: Bool) async -> CredentialRequest.Answer? {
        guard credentialRequest == nil else { return nil }
        return await withCheckedContinuation { continuation in
            credentialRequest = CredentialRequest(host: host, realm: realm, failed: failed, secure: secure) {
                [weak self] answer in
                self?.credentialRequest = nil
                continuation.resume(returning: answer)
            }
        }
    }

    /// What the page's script says is under the pointer (`LinkHover`).
    func linkHovered(_ raw: Any?) {
        let next = LinkStatus.text(raw)
        if next != hoveredLink { hoveredLink = next }
    }

    /// Stops the page's dialogs until it is left, and answers the one waiting as cancelled.
    package func silenceDialogs() {
        dialogPolicy.silence()
        dialog?.answer(.cancel)
    }
}
