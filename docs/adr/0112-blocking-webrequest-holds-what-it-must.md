---
status: accepted
date: 2026-11-21
---

# ADR-0112: Blocking `webRequest` holds requests, and documents' responses only

## Context

Our WebKit gives Manifest V2 extensions blocking `webRequest` (roadmap 0048 W6): a load waits for the extension's answer.
Each wait is a round trip, network process → UI process → the extension's page → back, and the extension's handler.
Measured with uBlock Origin from Firefox, 300 sequential requests (diary 2026-11-21-06): about 0.43 ms a request for the
request's hold (W6a) and as much again for the response's (W6c); the system's WebKit, which holds nothing, 449 ms against
650 ms with both. The owner, 2026-11-21: "make sure performances whatsoever are not impacted".

The request's hold is what blocking is: an ad not loaded is not sent. The response's hold lets an extension change headers
or cancel once headers are in. uBlock Origin's header filters (`$csp`, `$removeheader`) act on documents. A subresource's
headers decide little for the page.

## Decision

- Requests are held for blocking `onBeforeRequest` listeners, as in Firefox.
- Responses are held for blocking `onHeadersReceived` listeners only when they are documents (a frame's main resource).
  A subresource's response goes on; its listeners see it without a say.
- Each hold has its own flag: an extension that blocks requests only holds no responses.
- What an extension answers is checked: header names are HTTP tokens, values carry no line break or NUL.

## Consequences

- With uBlock Origin, a subresource pays one round trip (its request), a document two.
- Lost against Firefox: changing or cancelling a subresource at `onHeadersReceived` (uBlock Origin's `no-large-media`
  switch, off by default; extensions that rewrite CORS headers on subresources).
- Revisit if an extension we carry needs subresource headers: hold them for that extension's listeners only, or move the
  round trip off the UI process (network process to the extension's page).
