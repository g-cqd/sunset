# What still says WebKit when Sunset shows Chrome (task t15)

Roadmap 0046 D: impersonation beyond the user agent. What `AgentScript` already covers, and what a page can still read,
measured in Sunset (system's WebKit, `web.agent` "chrome") on 2026-11-21 with a test page. Chrome's values are what Chrome
prints for the same code: Chrome Canary would not start under the test harness (it crashes at launch here), so they are V8's
documented messages, to confirm on Chrome itself.

## Already covered (`AgentScript+Source.swift`)

`navigator.userAgent`, `vendor`, `platform`, `productSub`, `deviceMemory`, `userAgentData` with `getHighEntropyValues`,
`window.chrome` (`runtime`, `app`, `csi`, `loadTimes`), WebKit-only objects removed (`GestureEvent`, `WebKitPoint`,
`window.webkit`, force-touch handlers), and functions that print as native.

## What a page can still read

| Probe | Sunset as Chrome | Chrome (V8) | Fixable? |
|---|---|---|---|
| `null.x` | `null is not an object (evaluating 'null.x')` | `Cannot read properties of null (reading 'x')` | Only by rewriting error messages: every thrown TypeError would need catching and rewording; JavaScriptCore produces them in C++. Not from a script without breaking pages |
| `JSON.parse("{")` | `JSON Parse error: Expected '}'` | `Expected property name or '}' in JSON at position 1` | Same |
| `new Array(-1)` | `Array length must be a positive integer of safe magnitude.` | `Invalid array length` | Same |
| `new Error().stack`, first line | `global code@http://…:8:31` | `Error: x` then `    at …` | A wrapper on `Error` could reformat `stack`; fragile, pages read it for their own reports |
| Codecs: HEVC (`hvc1`) | `probably`; `MediaSource.isTypeSupported` true | Chrome on macOS: supported since Chrome 107 with hardware decoding | Matches |
| Codecs: HLS (`application/vnd.apple.mpegurl`) | `maybe` | `""` (Chrome plays HLS through MSE, not natively) | Yes: answer `""` as Chrome |
| Codecs: Theora | `""` | `""` since Chrome 123 | Matches |

## What it means

Error messages and stack traces come from the engine, in every catch block of every page: a page that wants to tell
JavaScriptCore from V8 can, and nothing short of running V8 changes that. Detection libraries (FingerprintJS and the like)
use them. Sunset's impersonation is for sites that **gate** on the user agent (their own code checks a string), not against
sites that **fingerprint** the engine; the threat model should say so (A1 fingerprints Sunset as WebKit whatever it shows).

Fixable: `canPlayType('application/vnd.apple.mpegurl')` answering as Chrome does. Done (`AgentScript`, for Chrome, Edge and
Firefox alike, which play HLS through Media Source Extensions only).

Not done: Firefox's values (SpiderMonkey's messages differ again); confirming Chrome's strings on Chrome itself.
