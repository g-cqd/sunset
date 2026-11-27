#!/usr/bin/env bash
# The web tester (Tools/webtester): what each browser can do, the same tests in Sunset, Safari, Chrome and Firefox.
#
#   Scripts/web-tester.sh                    serve it on http://localhost:8767 (Ctrl-C stops)
#   Scripts/web-tester.sh open [browsers]    serve it and open it in each (sunset safari chrome firefox; all by default)
#   Scripts/web-tester.sh check              run the automatic tests unattended where a browser can be: Chrome and
#                                            Firefox headless, in profiles of their own; Sunset, a test copy; WebKit, a
#                                            bare WKWebView. Each saves its results; then compare.html shows them.
#   Scripts/web-tester.sh extensions         the extension APIs: the test extension (Tools/webtester/extension) loaded
#                                            unattended where a browser allows it: WebKit's own extension host
#                                            (WKWebExtensionController), Firefox Nightly (unsigned, in a profile of its
#                                            own), Chrome (if its --load-extension still works); Safari by hand
#   Scripts/web-tester.sh safari             drive Safari through safaridriver: the automatic tests, the inventory, every
#                                            Ask clicked, dialogs answered, the extension installed (Safari must be quit)
#   Scripts/web-tester.sh mdn                MDN's documented support for the same extension APIs, as more columns
#   Scripts/web-tester.sh wpt                fetch the web-platform-tests the tester links to (into .build)
#
# Results are kept in .build/web-tester/results (one file per browser) and shown at /compare.html.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
port="${PORT:-8767}"
base="http://localhost:$port"
work="$here/.build/web-tester"
mkdir -p "$work/results"

app_of() {
    case "$1" in
        sunset) echo "$HOME/Applications/Sunset.app" ;;
        safari) echo "/Applications/Safari.app" ;;
        chrome) for a in "/Applications/Google Chrome.app" "/Applications/Google Chrome Canary.app" "/Applications/Chromium.app"; do [ -d "$a" ] && { echo "$a"; return; }; done ;;
        firefox) for a in "/Applications/Firefox.app" "/Applications/Firefox Nightly.app" "/Applications/Firefox Developer Edition.app"; do [ -d "$a" ] && { echo "$a"; return; }; done ;;
    esac
}

serve_in_background() {
    if curl -fs "$base/echo" > /dev/null 2>&1; then return; fi
    python3 "$here/Tools/webtester/server.py" "$port" "$work/results" "$work/wpt" > "$work/server.log" 2>&1 &
    server=$!
    trap 'kill "$server" 2>/dev/null || true' EXIT
    for _ in $(seq 1 50); do curl -fs "$base/echo" > /dev/null 2>&1 && return; sleep 0.1; done
    echo "the server did not start: $work/server.log" >&2
    exit 1
}

case "${1:-serve}" in
    serve)
        exec python3 "$here/Tools/webtester/server.py" "$port" "$work/results" "$work/wpt"
        ;;
    open)
        shift
        browsers=("$@")
        [ ${#browsers[@]} -eq 0 ] && browsers=(sunset safari chrome firefox)
        serve_in_background
        for b in "${browsers[@]}"; do
            app="$(app_of "$b")"
            if [ -z "$app" ] || [ ! -d "$app" ]; then echo "$b: not installed"; continue; fi
            open -a "$app" "$base/index.html?browser=$b"
            echo "$b: opened in $(basename "$app")"
        done
        echo "Serving on $base (Ctrl-C stops). Press Save results in each, then open $base/compare.html"
        wait
        ;;
    check)
        serve_in_background
        profiles="$(mktemp -d /tmp/web-tester-profiles.XXXXXX)"
        url() { echo "$base/index.html?browser=$1&auto=1"; }
        chrome="$(app_of chrome)"
        if [ -n "$chrome" ]; then
            binary="$chrome/Contents/MacOS/$(defaults read "$chrome/Contents/Info" CFBundleExecutable)"
            "$binary" --headless=new --no-first-run --no-default-browser-check --user-data-dir="$profiles/chrome" \
                --use-fake-ui-for-media-stream --use-fake-device-for-media-stream "$(url chrome-headless)" > /dev/null 2>&1 &
            pids+=($!)
            echo "chrome: headless ($(basename "$chrome"), fake camera and microphone)"
        fi
        firefox="$(app_of firefox)"
        if [ -n "$firefox" ]; then
            mkdir -p "$profiles/firefox"
            printf 'user_pref("media.navigator.streams.fake", true);\nuser_pref("media.navigator.permission.disabled", true);\nuser_pref("browser.shell.checkDefaultBrowser", false);\n' > "$profiles/firefox/user.js"
            "$firefox/Contents/MacOS/firefox" --headless --no-remote --profile "$profiles/firefox" "$(url firefox-headless)" > /dev/null 2>&1 &
            pids+=($!)
            echo "firefox: headless ($(basename "$firefox"), fake devices)"
        fi
        if [ -x "$here/.build/app-release/Sunset.app/Contents/MacOS/Sunset" ]; then
            folder="$profiles/sunset"
            mkdir -p "$folder"
            echo '{}' > "$folder/config.json"
            python3 - "$folder/session.json" "$(url sunset)" <<'PY'
import json, sys, uuid
pane = str(uuid.uuid4()).upper()
item = str(uuid.uuid4()).upper()
json.dump({"version": 2, "favorites": {"contents": [], "favorites": {"nodes": []}},
           "windows": [{"contents": [{"kind": "web", "pane": pane, "state": {"url": sys.argv[2]}}],
                        "workspace": {"items": [{"focused": pane, "id": item, "layout": {"pane": pane}}], "selected": item}}]},
          open(sys.argv[1], "w"))
PY
            frame="$(defaults read studio.aemi.sunset "NSWindow Frame terminal-AppWindow-1" 2>/dev/null || true)"
            SUNSET_CONFIG="$folder/config.json" SUNSET_SESSION="$folder/session.json" SUNSET_BACKGROUND=1 \
                "$here/.build/app-release/Sunset.app/Contents/MacOS/Sunset" > /dev/null 2>&1 &
            sunset=$!
            echo "sunset: a test copy (the build in .build/app-release)"
        fi
        swift "$here/Tools/webtester/webkit-check.swift" "$(url webkit)" > /dev/null 2>&1 &
        pids+=($!)
        echo "webkit: a bare WKWebView (the engine Safari and Sunset share, with nothing of either)"
        echo "waiting up to 60 s for the results…"
        for _ in $(seq 1 60); do
            sleep 1
            count=$(find "$work/results" -name '*.json' -newer "$profiles" | wc -l | tr -d ' ')
            [ "$count" -ge "$(( ${#pids[@]} + ${sunset:+1} ))" ] && break
        done
        for p in "${pids[@]}"; do kill "$p" 2>/dev/null || true; done
        if [ -n "${sunset:-}" ]; then
            kill "$sunset" 2>/dev/null || true
            sleep 1
            [ -n "$frame" ] && defaults write studio.aemi.sunset "NSWindow Frame terminal-AppWindow-1" -string "$frame"
        fi
        rm -rf "$profiles"
        python3 - "$work/results" <<'PY'
import json, pathlib, sys, collections
for f in sorted(pathlib.Path(sys.argv[1]).glob("*.json")):
    r = json.loads(f.read_text())
    c = collections.Counter(v["status"] for v in r["results"].values())
    print(f'{r["label"]:18} {r["date"][:19]}  ' + ", ".join(f"{k} {v}" for k, v in sorted(c.items())))
PY
        echo "Compare: Scripts/web-tester.sh, then $base/compare.html"
        ;;
    extensions)
        serve_in_background
        built="$work/extension"
        rm -rf "$built"
        cp -R "$here/Tools/webtester/extension" "$built"
        echo "{\"port\": $port}" > "$built/config.json"
        started="$(mktemp -d /tmp/web-tester-extensions.XXXXXX)"
        pids=()
        # WebKit's own host: what Sunset would start from.
        swiftc -O "$here/Tools/webtester/webkit-extension-check.swift" -o "$started/webkit-extension-check" 2>/dev/null
        codesign -s - -f "$started/webkit-extension-check" 2>/dev/null
        "$started/webkit-extension-check" "$built" > "$started/webkit.log" 2>&1 &
        pids+=($!)
        echo "webkit: WKWebExtensionController, every permission granted"
        # Firefox: Nightly and Developer Edition take an unsigned extension put in a profile.
        for firefox in "/Applications/Firefox Nightly.app" "/Applications/Firefox Developer Edition.app"; do
            [ -d "$firefox" ] || continue
            mkdir -p "$started/firefox/extensions"
            (cd "$built" && zip -qr "$started/firefox/extensions/web-tester@sunset.local.xpi" .)
            printf 'user_pref("xpinstall.signatures.required", false);\nuser_pref("extensions.autoDisableScopes", 0);\nuser_pref("extensions.enabledScopes", 15);\nuser_pref("browser.shell.checkDefaultBrowser", false);\n' > "$started/firefox/user.js"
            "$firefox/Contents/MacOS/firefox" --headless --no-remote --profile "$started/firefox" about:blank > "$started/firefox.log" 2>&1 &
            pids+=($!)
            echo "firefox: $(basename "$firefox"), headless, unsigned"
            break
        done
        # Chrome: --load-extension left branded builds in Chrome 137; the feature switch is tried, and may do nothing.
        chrome="$(app_of chrome)"
        if [ -n "$chrome" ]; then
            binary="$chrome/Contents/MacOS/$(defaults read "$chrome/Contents/Info" CFBundleExecutable)"
            "$binary" --headless=new --no-first-run --user-data-dir="$started/chrome" \
                --disable-features=DisableLoadExtensionCommandLineSwitch --load-extension="$built" about:blank > "$started/chrome.log" 2>&1 &
            pids+=($!)
            echo "chrome: $(basename "$chrome"), headless, --load-extension tried"
        fi
        echo "waiting 30 s…"
        sleep 30
        for p in "${pids[@]}"; do kill "$p" 2>/dev/null || true; done
        sleep 1
        python3 - "$work/results" "$started" <<'PY'
import json, os, pathlib, sys, collections
since = os.path.getmtime(sys.argv[2])
for f in sorted(pathlib.Path(sys.argv[1]).glob("*-extension.json")):
    r = json.loads(f.read_text())
    fresh = "new" if f.stat().st_mtime >= since else "old"
    c = collections.Counter(v["status"] for v in r["results"].values())
    print(f'{r["label"]:20} ({fresh})  ' + ", ".join(f"{k} {v}" for k, v in sorted(c.items())))
PY
        rm -rf "$started"
        echo "Safari, Chrome by hand: load $built (Safari: Settings › Developer › Add Temporary Extension…;"
        echo "Chrome: chrome://extensions › Developer mode › Load unpacked). It saves its results itself."
        ;;
    safari)
        serve_in_background
        built="$work/extension"
        rm -rf "$built"
        cp -R "$here/Tools/webtester/extension" "$built"
        echo "{\"port\": $port}" > "$built/config.json"
        python3 "$here/Tools/webtester/safari-drive.py" "$base" "$built"
        ;;
    mdn)
        # MDN browser-compat-data's support for every member the extension probes: one report per browser, "<browser>-mdn".
        node - "$here/Tools/webtester/extension/probes.js" "$work/results" <<'JS'
const fs = require("fs");
const [source, out] = process.argv.slice(2);
const text = fs.readFileSync(source, "utf8");
const probes = new Function(text + "; return probes;")();
const browsers = { chrome: "chrome", firefox: "firefox", safari: "safari", edge: "edge" };
(async () => {
  const reports = Object.fromEntries(Object.keys(browsers).map((b) => [b, {}]));
  for (const [namespace, members] of probes) {
    let data;
    try {
      const answer = await fetch(`https://raw.githubusercontent.com/mdn/browser-compat-data/main/webextensions/api/${namespace}.json`);
      data = answer.ok ? (await answer.json()).webextensions.api[namespace] : null;
    } catch { data = null; }
    const entries = [[`ext:${namespace}`, namespace, data?.__compat]];
    for (const m of members) {
      const name = Array.isArray(m) ? m[0] : m;
      entries.push([`ext:${namespace}.${name}`, `${namespace}.${name}`, data?.[name]?.__compat]);
    }
    for (const [id, name, compat] of entries) {
      for (const b of Object.keys(browsers)) {
        let support = compat?.support?.[b];
        if (Array.isArray(support)) support = support[0];
        const added = support?.version_added;
        const status = !compat ? "skip" : added && added !== "preview" ? (support.partial_implementation ? "partial" : "yes") : "no";
        const detail = !compat ? "not in MDN's data" : added ? `since ${added}${support.notes ? " (notes)" : ""}` : "not supported";
        reports[b][id] = { group: `Extension: ${namespace}`, name, kind: "auto", status, detail, ms: 0 };
      }
    }
  }
  for (const [b, results] of Object.entries(reports)) {
    const label = `${b}-mdn`;
    fs.writeFileSync(`${out}/${label}.json`, JSON.stringify({ label, kind: "extension", source: "MDN browser-compat-data", date: new Date().toISOString(), userAgent: "documented support", results }, null, 2));
    console.log(`${label}: ${Object.values(results).filter((r) => r.status === "yes").length} documented as supported`);
  }
})();
JS
        ;;
    wpt)
        # The web-platform-tests the tester links to: a shallow, sparse checkout (only these folders, and what they share).
        dest="$work/wpt"
        if [ ! -d "$dest/.git" ]; then
            git clone --depth 1 --filter=blob:none --sparse https://github.com/web-platform-tests/wpt "$dest"
        fi
        git -C "$dest" sparse-checkout set resources common mediacapture-streams screen-capture webrtc \
            mediacapture-record mediacapture-fromelement permissions notifications clipboard-apis screen-wake-lock \
            fullscreen picture-in-picture webauthn web-share geolocation storage storage-access-api service-workers \
            html/semantics/embedded-content/media-elements media-capabilities webcodecs
        git -C "$dest" log -1 --format='web-platform-tests at %h (%cs)'
        echo "Serve with Scripts/web-tester.sh, then open $base/wpt.html"
        ;;
    *)
        sed -n '2,15p' "$0"
        exit 2
        ;;
esac
