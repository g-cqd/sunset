# Web tester

What a browser can do, the same tests in Sunset, Safari, Chrome and Firefox, side by side. Served on localhost (a
secure context, as https is), by `Scripts/web-tester.sh`.

| Page | What |
|---|---|
| `index.html` | About 300 tests in groups. The automatic ones run at once and prompt for nothing: platform and identity, permissions' state, media capture, WebRTC (data and video loopbacks in the page), media formats (decode, encode, record, HLS, MSE), graphics (WebGL, WebGPU, CSS), storage and workers, network (the headers sent, server-sent events, streams), newer platform APIs, devices present. Those under **Asks** each need a click (capture and sharing, permissions, clipboard, files, devices, passkeys, DRM, full screen, picture in picture, pointer and keyboard lock, pop-ups and dialogs, with and without a gesture) and say what the browser answered. **Save results** keeps them on the server. |
| `calls.html` | A call: devices chosen, constraints, a level meter, sharing, stopping, a loopback through two peer connections with its statistics. |
| `compare.html` | The saved results side by side, web APIs or extension APIs; rows where browsers differ in bold; files from another machine can be added. |
| `extension/` | A Manifest V3 extension that probes about 170 extension APIs from its background (each namespace and member; called where it can be without a click) and saves them. Its ids are MDN's (`ext:<namespace>.<member>`), so its columns sit beside MDN's documented support. |
| `inventory.html` | Every interface and member a page sees at runtime, per browser (**Save API inventory**, or an unattended run); two compared: what one has that the other has not. |
| `wpt.html` | The web-platform-tests folders about the same APIs, run here by hand (`Scripts/web-tester.sh wpt` fetches them). |
| `/isolated/` | The same pages cross-origin isolated (COOP, COEP): SharedArrayBuffer. |
| `/echo` | The request's headers: what a browser says it is. |

## Running it

```
Scripts/web-tester.sh                  # serve on http://localhost:8767
Scripts/web-tester.sh open             # serve, and open in Sunset, Safari, Chrome and Firefox (each labelled)
Scripts/web-tester.sh check            # the automatic tests unattended: Chrome and Firefox headless (fake devices),
                                       # a Sunset test copy, a bare WKWebView
Scripts/web-tester.sh extensions       # the extension unattended: WebKit's host, Firefox Nightly
Scripts/web-tester.sh mdn              # MDN's documented support for the same extension APIs
Scripts/web-tester.sh wpt              # fetch the web-platform-tests folders
Scripts/web-tester.sh safari           # drive Safari (safaridriver): automatic tests, inventory, every Ask clicked,
                                       # dialogs answered, the extension installed; Safari must be quit first
```

`PORT=8769 Scripts/web-tester.sh …` for another port. Results live in `.build/web-tester/results`, one file per browser.

**By hand**: Safari loads the extension from Settings › Developer › Add Temporary Extension… (the folder
`.build/web-tester/extension`, made by `extensions`, names the port); Chrome from chrome://extensions › Developer mode ›
Load unpacked (Chrome 137 removed `--load-extension` from its branded builds, so it cannot be loaded unattended). Each
saves its results by itself.

## What it is not

- Not a conformance suite: that is web-platform-tests, which Chromium, Firefox and WebKit share (`wpt.html`). A test that
  grants itself a permission through `testdriver` needs `./wpt run` (WebDriver, a hosts file), not this server.
- A browser's "yes" means the API answered here, on localhost, with this machine's devices; not that every part of it
  works. Its detail says what it answered.

## Prior art (read 2026-11-19)

- WebRTC samples, by the Chromium WebRTC team: <https://webrtc.github.io/samples/> (<https://github.com/webrtc/samples>),
  and their test pages: <https://webrtc.github.io/test-pages/>.
- Mozilla's WebRTC landing page: <https://mozilla.github.io/webrtc-landing/>.
- web-platform-tests: <https://github.com/web-platform-tests/wpt>, results at <https://wpt.fyi>; how to run them:
  <https://web-platform-tests.org/running-tests/from-local-system.html>.
- MDN browser-compat-data, its extension APIs: <https://github.com/mdn/browser-compat-data/tree/main/webextensions/api>.
- WebKit's extension host, `WKWebExtensionController` (macOS 15.4).
