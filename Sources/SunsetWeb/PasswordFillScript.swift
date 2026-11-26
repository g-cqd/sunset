/// The scripts of filling and saving (roadmap 0094), run in Sunset's own world.
enum PasswordFillScript {
    /// Tells the focus of a sign-in field and where it is; and, `saving`, a password sent with its username.
    static func watch(saving: Bool, handler: String) -> String {
        """
        (() => {
          // Looked up when posting: the handler is the world's own, present whenever a message is sent.
          const post = (message) => webkit.messageHandlers.\(handler).postMessage(message);
          \(fields)
          let shown = null;
          // Only what the person does: an event the page made up (a focus, a submit, a key or a click it dispatches)
          // shows nothing and offers nothing.
          addEventListener('focusin', (e) => {
            if (!e.isTrusted) return;
            const role = roleOf(e.target);
            if (role && visible(e.target)) {
              const r = e.target.getBoundingClientRect();
              shown = e.target;
              post({ kind: 'focus', role, x: r.left, y: r.top, width: r.width, height: r.height,
                     rules: e.target.getAttribute('passwordrules') || null });
            } else if (shown) {
              shown = null;
              post({ kind: 'blur' });
            }
          }, true);
          // The page going away (a navigation, a reload, its tab closed): its suggestions go with it.
          addEventListener('pagehide', () => { if (shown) { shown = null; post({ kind: 'blur' }); } }, true);
          addEventListener('focusout', (e) => {
            if (!e.isTrusted) return;
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
          addEventListener('submit', (e) => { if (e.isTrusted) send(e.target); }, true);
          addEventListener('keydown', (e) => { if (e.isTrusted && e.key === 'Enter' && e.target && e.target.form !== undefined) send(scope(e.target)); }, true);
          addEventListener('click', (e) => {
            if (!e.isTrusted) return;
            const button = e.target && e.target.closest && e.target.closest('button, input[type=submit], [role=button]');
            if (button) send(scope(button));
          }, true);
        })();
        """
    }

    /// What makes an input a sign-in field, and which: shared by the watch and the fill.
    static var fields: String {
        """
        // Shown and usable: connected, enabled, writable, of some size, not hidden by its style.
        const visible = (el) => {
          if (!el || !el.isConnected || el.disabled || el.readOnly) return false;
          const box = el.getBoundingClientRect();
          if (box.width <= 1 || box.height <= 1) return false;
          const style = getComputedStyle(el);
          return style.visibility !== 'hidden' && style.display !== 'none' && Number(style.opacity) > 0.05;
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
        // A value set as typing sets it: through the field's own setter, then its input and change events.
        const set = (el, value) => {
          const kind = el instanceof HTMLTextAreaElement ? HTMLTextAreaElement : HTMLInputElement;
          Object.getOwnPropertyDescriptor(kind.prototype, 'value').set.call(el, value);
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
        };
        // A menu's option chosen by its value or its text, either of `wanted` in any case; whether one was.
        const pick = (select, wanted) => {
          const lower = wanted.map(w => String(w).toLowerCase());
          const option = [...select.options].find(o => lower.includes(o.value.toLowerCase()) || lower.includes(o.text.trim().toLowerCase()));
          if (!option) return false;
          select.value = option.value;
          select.dispatchEvent(new Event('change', { bubbles: true }));
          return true;
        };
        // A one-time code's field: its token; a short field named for a code; or a box of a code split one character a
        // box (maxlength 1, among five to eight such boxes in its parent).
        const boxes = (el) => el && el.parentElement ? [...el.parentElement.querySelectorAll('input')].filter(i => i.maxLength === 1 && visible(i)) : [];
        // A card's field: its `cc-` token, or its name (number, holder, expiry, security code).
        const cardPart = (el) => {
          if (!(el instanceof HTMLInputElement || el instanceof HTMLSelectElement) || !visible(el)) return null;
          const token = (el.autocomplete || '').match(/cc-(number|name|exp-month|exp-year|exp|csc)/);
          if (token) return token[1];
          const name = (el.name + ' ' + el.id).toLowerCase();
          if (/card.?num|cc.?num|cardnumber/.test(name)) return 'number';
          if (/card.?holder|name.?on.?card|cc.?name/.test(name)) return 'name';
          if (/exp.*month|cc.?month/.test(name)) return 'exp-month';
          if (/exp.*year|cc.?year/.test(name)) return 'exp-year';
          if (/expir|exp.?date|cc.?exp/.test(name)) return 'exp';
          if (/cvc|cvv|csc|security.?code/.test(name)) return 'csc';
          return null;
        };
        const isCode = (el) => {
          if (!(el instanceof HTMLInputElement) || !['text', 'tel', 'number', ''].includes(el.type)) return false;
          if (/one-time-code/.test(el.autocomplete || '')) return true;
          const named = /otp|one.?time|2fa|totp|mfa|verif|security.?code|auth.?code|passcode|^code$/i.test(el.name + ' ' + el.id);
          if (named && (el.maxLength <= 0 || el.maxLength <= 10)) return true;
          const n = boxes(el).length;
          return el.maxLength === 1 && n >= 5 && n <= 8;
        };
        const roleOf = (el) => {
          // A new password: its token; or a form of two or three password fields (a password and its confirmation),
          // none of them a current one.
          if (isPassword(el)) {
            if (/new-password/.test(el.autocomplete || '')) return 'newPassword';
            const all = passwords(scope(el));
            const current = all.some(f => /current-password/.test(f.autocomplete || ''));
            return all.length >= 2 && all.length <= 3 && !current ? 'newPassword' : 'password';
          }
          if (isCode(el)) return 'oneTimeCode';
          if (cardPart(el)) return 'card';
          if (isText(el) && passwords(scope(el)).length > 0 && usernameOf(scope(el)) === el) return 'username';
          if (isText(el) && /username/.test(el.autocomplete || '')) return 'username';
          if (identityPart(el)) return 'identity';
          return null;
        };
        \(identityFields)
        """
    }

    /// Fills the form of the field that has the keyboard (else the first with a visible password): its visible username
    /// and password fields, as typing would (the value set through the input's own setter, then input and change
    /// events). Returns whether a password field was filled.
    static let fill = """
        \(fields)
        const root = scope(document.activeElement && roleOf(document.activeElement) ? document.activeElement : passwords()[0]);
        const password = passwords(root)[0];
        if (!password) return false;
        const user = usernameOf(root);
        if (user && username.length > 0) set(user, username);
        set(password, secret);
        return true;
        """

    /// Fills a new password into the form of the field that has the keyboard: every visible password field of it (the
    /// password and its confirmation), nothing else. Returns whether one was filled.
    static let fillNew = """
        \(fields)
        const el = document.activeElement;
        if (!isPassword(el)) return false;
        const all = passwords(scope(el));
        all.forEach(field => set(field, secret));
        return all.length > 0;
        """

    /// Fills a one-time code into the code field that has the keyboard, or one character a box into a code split in boxes.
    static let fillCode = """
        \(fields)
        const el = document.activeElement;
        if (!isCode(el)) return false;
        const split = el.maxLength === 1 ? boxes(el) : [];
        if (split.length >= code.length) {
          [...code].forEach((c, i) => set(split[i], c));
        } else {
          set(el, code);
        }
        return true;
        """

    /// Fills a card into the form of the field that has the keyboard: each of its card fields with its value; an expiry
    /// in one field as its length allows ("MM/YY" or "MM/YYYY"); a month or a year in a menu by the option that means it.
    static let fillCard = """
        \(fields)
        const el = document.activeElement;
        if (!cardPart(el)) return false;
        const put = (field, values) => field instanceof HTMLSelectElement ? pick(field, values) : set(field, values[0]);
        const yy = year.slice(-2);
        const month1 = String(Number(month));
        for (const field of (el.form || document).querySelectorAll('input, select')) {
          switch (cardPart(field)) {
            case 'number': put(field, [number]); break;
            case 'name': put(field, [name]); break;
            case 'exp': put(field, [field.maxLength >= 7 ? month + '/' + year : month + '/' + yy]); break;
            case 'exp-month': put(field, [month, month1]); break;
            case 'exp-year': put(field, field instanceof HTMLSelectElement ? [year, yy] : [field.maxLength === 2 ? yy : year]); break;
            case 'csc': put(field, [code]); break;
          }
        }
        return true;
        """
}
