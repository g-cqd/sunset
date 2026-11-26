/// Filling as a page loads (ADR-0094, t103), when the person allows it: the watch tells the app once a document that a
/// sign-in form is shown, and the app may fill it with the site's one login.
extension PasswordFillScript {
    /// Part of `watch`, not in a private window: tells, once, the first sign-in password field shown, at load or when
    /// the page's script adds it within ten seconds. A sign-up form's (a new password) is not one.
    static let formShown = """
        let told = false, pending = false;
        const tell = () => {
          const password = passwords().find(p => roleOf(p) === 'password');
          if (told || !password) return;
          told = true;
          watching.disconnect();
          const r = password.getBoundingClientRect();
          post({ kind: 'form', x: r.left, y: r.top, width: r.width, height: r.height });
        };
        const watching = new MutationObserver(() => {
          if (pending || told) return;
          pending = true;
          setTimeout(() => { pending = false; tell(); }, 200);
        });
        watching.observe(document, { childList: true, subtree: true, attributes: true, attributeFilter: ['style', 'class', 'hidden'] });
        setTimeout(() => watching.disconnect(), 10000);
        tell();
        """

    /// Fills the first sign-in form shown with `username` and `secret`, as `fill`, but only if the person has not typed
    /// in it yet, and only if it is sent to the page's own origin. Returns whether it was filled.
    static let fillOnLoad = """
        \(fields)
        const password = passwords().find(p => roleOf(p) === 'password');
        if (!password || password.value.length > 0) return false;
        const root = scope(password);
        const form = password.form;
        if (form && form.getAttribute('action') !== null) {
          try {
            if (new URL(form.action, location.href).origin !== self.origin) return false;
          } catch { return false; }
        }
        const user = usernameOf(root);
        if (user && user.value.length > 0 && user.value !== username) return false;
        if (user && username.length > 0) set(user, username);
        set(password, secret);
        return true;
        """
}
