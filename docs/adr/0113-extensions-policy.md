---
status: accepted
date: 2026-11-21
---

# ADR-0113: What an extension may do in Sunset

The threat model (docs/design/0006, adversary A9) asked for this table before the first extension; extensions have run since
roadmap 0109. It says what each permission an extension can hold lets it do in Sunset, who grants it, and what limits it,
as the code stands on 2026-11-21. Sunset's code and WebKit's (our base 944f9ff672) were read for it.

## How permissions are granted

| When | What | Where in the code |
|---|---|---|
| At install | The person sees the extension's name, what it says of itself, and its permissions in plain words (`ExtensionWording`); **Add Extension** grants every API permission and site pattern the manifest asks; Cancel installs nothing | `ExtensionPrompt`, `ExtensionHost.install` |
| At each launch | Exactly what was granted at install, by name; nothing else | `ExtensionHost.grant` |
| Later (`permissions.request`, optional permissions) | **Nothing**: Sunset has no prompt for it, so WebKit answers the request with nothing granted (`WebExtensionContext::requestPermissions`, no `promptForPermissions` delegate) | — |
| Private windows | Only an extension the person allowed there | `hasAccessToPrivateData` |
| Pages the person did not grant | The extension acts only on its granted site patterns (`activeTab` adds the page in front, for the click that asked) | WebKit |

## What a permission lets it do

| Permission | In Sunset (system's WebKit) | In Sunset WebKit (our patches) | Limit |
|---|---|---|---|
| Site patterns (`<all_urls>`, hosts) | Read and change those pages (content scripts, CSS) | Same | Only granted patterns; not Sunset's own pages, not other extensions' |
| `tabs` | See open tabs' titles and addresses; open, move, close tabs | Same | — |
| `webNavigation` | See which pages are opened | Same | — |
| `webRequest` (observe) | — (not in the system's WebKit) | See every request to granted sites, with headers | Granted sites only |
| `webRequest` + `webRequestBlocking` | — | **Cancel or redirect requests; change a request's headers; change a document's response headers**, which removes its `Content-Security-Policy`, frame protection or `Set-Cookie` (ADR-0112) | Granted sites only; responses of documents and frames only; header names and values must be well-formed; the request is held at most until the extension answers |
| `declarativeNetRequest` | Block, redirect, change headers by rules | Same | WebKit's rule limits |
| `cookies` | Read and change cookies of granted sites, `HttpOnly` included | Same | Granted sites; the person's profile only |
| `history`, `bookmarks`, `downloads` | As WebKit implements them (history and bookmarks: Sunset does not provide them yet) | Same | — |
| `scripting` | Run scripts in granted pages | Same | Granted sites |
| `storage`, `unlimitedStorage` | Its own storage | Same | Its own; not sealed at quit (threat model, extensions' storage) |
| `clipboardWrite` / `clipboardRead` | Write / read the clipboard | Same | Read: worded as such at install |
| `nativeMessaging` | **Nothing**: Sunset answers no native message | Same | — |
| `proxy` | — | — | Not implemented (roadmap 0109) |
| `notifications` | Notifications | Same | Sunset's notification permission |

## What this decides

1. Install-time consent stays the only grant until Sunset has a prompt for later requests; then a later request will ask the
   person, per permission, and be refused by default.
2. An extension holding blocking `webRequest` on a site can disable that site's own protections (CSP, frame options) and
   read or change its cookies: the install prompt says so in words ("Block, redirect or change requests, and a page's
   security headers"; before 2026-11-21 it showed the permission's name), and Sunset WebKit's release note names header
   rewriting.
3. Native messaging stays off: it would let an extension reach a program outside the browser's sandbox.

## Not covered

What WebKit itself enforces inside each permission (taken as WebKit implements it; our patches add only what the table says);
an audit of each API's implementation in WebKit.
