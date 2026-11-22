/// The scripts of filling and saving (roadmap 0094), run in Sunset's own world.
enum PasswordFillScript {
    /// What makes an input a sign-in field, and which: shared by the watch and the fill.
    static let fields = """
        const visible = (el) => {
          if (!el || !el.isConnected || el.disabled || el.readOnly) return false;
          const r = el.getBoundingClientRect(), s = getComputedStyle(el);
          return r.width > 1 && r.height > 1 && s.visibility !== 'hidden' && s.display !== 'none' && Number(s.opacity) > 0.05;
        };
        const isPassword = (el) => el instanceof HTMLInputElement && el.type === 'password';
        const isText = (el) => el instanceof HTMLInputElement && ['text', 'email', 'tel', ''].includes(el.type);
        const passwords = (root) => [...(root || document).querySelectorAll('input[type=password]')].filter(visible);
        // The username of a form: its autocomplete one, else the last visible text field before its first password.
        const usernameOf = (root) => {
          const inputs = [...(root || document).querySelectorAll('input')].filter(visible);
          const tagged = inputs.find(el => isText(el) && /username|email/.test(el.autocomplete || ''));
          if (tagged) return tagged;
          const first = inputs.findIndex(isPassword);
          return first > 0 ? inputs.slice(0, first).reverse().find(isText) : undefined;
        };
        const scope = (el) => (el && el.form) || document;
        const roleOf = (el) => {
          if (isPassword(el)) return /new-password/.test(el.autocomplete || '') ? 'newPassword' : 'password';
          if (isText(el) && passwords(scope(el)).length > 0 && usernameOf(scope(el)) === el) return 'username';
          if (isText(el) && /username/.test(el.autocomplete || '')) return 'username';
          return null;
        };
        """

    /// Tells the focus of a sign-in field and where it is; and, `saving`, a password sent with its username.
    static func watch(saving: Bool, handler: String) -> String {
        """
        (() => {
          // Looked up when posting: the handler is the world's own, present whenever a message is sent.
          const post = (message) => webkit.messageHandlers.\(handler).postMessage(message);
          \(fields)
          let shown = null;
          addEventListener('focusin', (e) => {
            const role = roleOf(e.target);
            if (role && visible(e.target)) {
              const r = e.target.getBoundingClientRect();
              shown = e.target;
              post({ kind: 'focus', role, x: r.left, y: r.top, width: r.width, height: r.height });
            } else if (shown) {
              shown = null;
              post({ kind: 'blur' });
            }
          }, true);
          addEventListener('focusout', (e) => {
            if (e.target === shown && !e.relatedTarget) { shown = null; post({ kind: 'blur' }); }
          }, true);
          if (!\(saving)) return;
          let sent = false;
          const send = (root) => {
            const password = passwords(root).find(f => f.value.length > 0);
            if (sent || !password) return;
            sent = true;
            const user = usernameOf(root);
            const r = password.getBoundingClientRect();
            post({ kind: 'sent', username: user ? user.value : '', password: password.value,
                   x: r.left, y: r.top, width: r.width, height: r.height });
          };
          addEventListener('submit', (e) => send(e.target), true);
          addEventListener('keydown', (e) => { if (e.key === 'Enter' && e.target && e.target.form !== undefined) send(scope(e.target)); }, true);
          addEventListener('click', (e) => {
            const button = e.target && e.target.closest && e.target.closest('button, input[type=submit], [role=button]');
            if (button) send(scope(button));
          }, true);
        })();
        """
    }

    /// Fills the form of the field that has the keyboard (else the first with a visible password): its visible username
    /// and password fields, as typing would (the value set through the input's own setter, then input and change
    /// events). Returns whether a password field was filled.
    static let fill = """
        \(fields)
        const root = scope(document.activeElement && roleOf(document.activeElement) ? document.activeElement : passwords()[0]);
        const set = (el, value) => {
          Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(el, value);
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
        };
        const password = passwords(root)[0];
        if (!password) return false;
        const user = usernameOf(root);
        if (user && username.length > 0) set(user, username);
        set(password, secret);
        return true;
        """
}
