# The web's credential, security and payment APIs; filling and saving (2026-11-19)

## What WebKit's views have, against Safari

From the inventories (diary 2026-11-19-04, -05) and the probes of this research (`payments.swift`, `features.swift`):

| API | Safari | Sunset now | WebKit's flag | With the flag on (probed, bare WKWebView) |
|---|---|---|---|---|
| `ApplePaySession` (Apple Pay JS) | yes | no | `ApplePayEnabled`, off by default | Present; `canMakePayments()` true; `supportsVersion(14)` true |
| `PaymentRequest` (+ `PaymentAddress`, `MerchantValidationEvent`, `PaymentMethodChangeEvent`) | yes | no | the same flag | Present; a `PaymentRequest` for `https://apple.com/apple-pay` is made |
| `DigitalCredential` | yes | no | `DigitalCredentialsEnabled` (status 6), off | Present; not exercised |
| `PublicKeyCredential` (WebAuthn) | yes, works | present, refused | — | `create` refused in 12 ms without the browser entitlement ([hardware-keys.md](hardware-keys.md)); `getClientCapabilities()` claims `passkeyPlatformAuthenticator: true` while `isUserVerifyingPlatformAuthenticatorAvailable()` is false: a page can tell |
| `PasswordCredential`, `FederatedCredential`, `IdentityCredential` (FedCM), `OTPCredential` (WebOTP) | no | no | — | Chrome's; adding them would tell Sunset from Safari |
| `IdleDeadline`, Push (`PushManager`), `MediaSessionCoordinator` | yes | no | — | Task t98, not credentials |

## Apple Pay in a page

- **WebKit's claim (Safari 13 post, 2019, theirs):** in a WKWebView, "Apple Pay cannot be used alongside of script
  injection APIs such as `WKUserScript` or `evaluateJavaScript`". If they run before the page uses Apple Pay, it is
  disabled until the top frame navigates.
- **Probed** (`applepay-begin.swift`):
  - The flag on, a real click, `new ApplePaySession(3, …).begin()`, with no user script and then with one. In both:
    `begun`, then `cancelled`, without `onvalidatemerchant`.
  - The log: WebKit's `PaymentCoordinator::beginPaymentSession() -> 1`, and PassKit launched
    `com.apple.PassKit.PaymentAuthorizationUIExtension`.
  - So the script injection did not stop the session at `begin`. Something after it cancelled; the reason was not found in
    the log.
- **Open, with the owner on screen:**
  - whether the sheet shows and why it closes (no card in Wallet on this Mac? the ad hoc signature? the merchant?);
  - then Apple's demo merchant (applepaydemo.apple.com), whose merchant validation is real.
  - Until then, Sunset keeps the flag off: a page that offers Apple Pay and then fails is worse than one that offers
    another way.
  - With the flag off, sites using Apple's JS SDK may offer their QR code flow for browsers without Apple Pay (Apple's
    claim, WWDC 2024: paying from a third-party browser by scanning with an iPhone). To check on a real shop.
- **Payment Request beyond Apple Pay:** WebKit's `PaymentRequest` supports only Apple Pay's method, so there is no "basic
  card" to give.
- **Cards from the vault:** filled into `autocomplete="cc-*"` fields, as Safari fills its own. A Card entry holds number,
  name, expiry and security code (concealed). The fill engine below; the security code is asked to be revealed each
  time, never filled automatically.

## Filling and saving: the engine

- **Where it runs.** In Sunset's own content world, as `SignInWatch` does today. A page's scripts cannot see it, call it, or
  post to it (the policy behind ADR-0089). It runs in every frame; what it may fill in a frame depends on that frame's
  origin (from `WKFrameInfo`), never on what the page says.
- **Finding fields:**
  - `autocomplete` tokens first (username, current-password, new-password, one-time-code, cc-*, address parts, email, tel);
  - then types and heuristics: a password field and the text field before it, a form's action, labels;
  - open shadow roots too.
  - Apple keeps an MIT-licensed list of per-site quirks (password rules, shared logins between domains:
    `apple/password-manager-resources`). Taking it is a data dependency, which is the owner's call (white paper §8).
- **Matching an entry to a page:**
  - By registrable domain by default (`accounts.example.co.uk` matches `example.co.uk`). That needs the Public Suffix List:
    a data file, updated; also the owner's call. Without it, by host only.
  - Per URL, the entry may say host, exact, prefix, regex or never.
  - Shown with the site's real host, the punycode form visible for internationalised names (homographs).
- **Filling:** on the person's act, from Sunset's suggestion under the field (native, outside the page: the page cannot
  draw over it or read it) or a key. Automatic fill on load only if the person allows it and only for an exact match; it
  never reaches hidden fields or cross-origin frames.
- **Saving:** `SignInWatch` already sees a password sent. It grows to read the username and password at that moment, in its
  own world, and Sunset offers "Save" or "Update" in a bar outside the page; dismissing it is remembered per site.
- **New passwords:** a `new-password` field gets a generated suggestion honouring `passwordrules`, saved as a draft before
  the form is sent so that a failed sign-up does not lose it.
- **Passkeys in pages, once the entitlement is granted (t49):**
  - Sunset answers `navigator.credentials.create` / `get`, replacing WebKit's: shaped as WebKit's (ADR-0089), relayed to
    `ASAuthorizationController` with the frame's origin, the client data built by `ASPublicKeyCredentialClientData`.
  - Conditional mediation (`mediation: "conditional"`): Sunset's suggestion lists the site's passkeys from
    `platformCredentials(forRelyingParty:)` beside its passwords.

## The policies

The vault's policies are in [vault.md](vault.md). For payments:
- the payment sheet only from a person's gesture (WebKit's own rule);
- a card's security code never filled without a reveal.
