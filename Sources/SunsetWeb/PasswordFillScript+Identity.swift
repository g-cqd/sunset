/// Contact and address fields (roadmap 0094, t103): which a field is, and filling a form's from an identity
/// (`IdentityOffer`).
extension PasswordFillScript {
    /// What makes a field a contact or address one, and which: its HTML autofill token (after a section, `shipping` or
    /// `billing`), else its type (`email`, `tel`), else its name. Part of `fields`.
    static let identityFields = """
        const identityTokens = ['given-name', 'family-name', 'name', 'email', 'tel', 'street-address', 'address-line1',
          'address-line2', 'address-line3', 'address-level2', 'address-level1', 'postal-code', 'country', 'country-name'];
        const identityNames = [
          [/first.?name|given.?name|fname/, 'given-name'], [/last.?name|family.?name|surname|lname/, 'family-name'],
          [/e-?mail/, 'email'], [/phone|mobile|^tel/, 'tel'], [/zip|postal|postcode/, 'postal-code'],
          [/city|town/, 'address-level2'], [/state|province|region|county/, 'address-level1'], [/country/, 'country'],
          [/address.?(line)?.?2|addr2/, 'address-line2'], [/address|street|addr/, 'address-line1'],
          [/^(full.?|your.?)?name$/, 'name']];
        const identityPart = (el) => {
          const kind = el instanceof HTMLInputElement || el instanceof HTMLSelectElement || el instanceof HTMLTextAreaElement;
          if (!kind || !visible(el) || (el instanceof HTMLInputElement && !isText(el))) return null;
          const tokens = (el.getAttribute('autocomplete') || '').toLowerCase().split(/\\s+/);
          const token = tokens.find(t => identityTokens.includes(t));
          if (token) return token;
          if (el.type === 'email' || el.type === 'tel') return el.type;
          for (const name of [el.name, el.id].map(n => (n || '').toLowerCase())) {
            const found = identityNames.find(([pattern]) => pattern.test(name));
            if (found) return found[1];
          }
          return null;
        };
        """

    /// Fills the form of the contact or address field that has the keyboard from `values` (by token): each of its
    /// visible contact and address fields there is a value for, none of its passwords, codes or card fields; a street
    /// of several lines on one line where the field has one; a country in a menu by its code or its name. Returns
    /// whether one was filled.
    static let fillIdentity = """
        \(fields)
        const el = document.activeElement;
        if (!identityPart(el)) return false;
        const countryName = (code) => {
          if (!/^[a-z]{2}$/i.test(code)) return [];
          try {
            return [navigator.language, 'en'].map(l => new Intl.DisplayNames([l], { type: 'region' }).of(code.toUpperCase()));
          } catch { return []; }
        };
        let filled = false;
        for (const field of (el.form || document).querySelectorAll('input, select, textarea')) {
          if (isPassword(field) || isCode(field) || cardPart(field)) continue;
          const part = identityPart(field);
          const country = part === 'country' || part === 'country-name';
          const value = country ? values['country'] : values[part];
          if (!value) continue;
          if (field instanceof HTMLSelectElement) {
            filled = pick(field, [value, ...(country ? countryName(value) : [])]) || filled;
          } else {
            const shown = part === 'country-name' ? (countryName(value)[0] || value) : value;
            set(field, field instanceof HTMLTextAreaElement ? shown : shown.split(/\\n+/).join(', '));
            filled = true;
          }
        }
        return filled;
        """
}
