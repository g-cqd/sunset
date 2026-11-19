// Automatic tests: run at once, prompt for nothing, open no picker, ask for no device. What exists, and what works
// without asking: storage, workers, network, codecs, graphics, WebRTC with a canvas.
import { define, exists, yes, no, partial, skip, at, pause } from "./core.js";

const css = (id, name, rule) => ({ id, name, run: () => (CSS.supports(rule) ? yes(rule) : no(rule)) });

// ——— Platform: what a page may do at all.
define("Platform", [
  { id: "secure", name: "Secure context", run: () => (isSecureContext ? yes(location.origin) : no("http on a non-local host: most of what follows is off")) },
  { id: "isolated", name: "Cross-origin isolated", run: () => (crossOriginIsolated ? yes("COOP + COEP") : partial("not isolated: open /isolated/ for SharedArrayBuffer and precise timers")) },
  { id: "sab", name: "SharedArrayBuffer", run: () => (typeof SharedArrayBuffer === "function" ? yes() : no(crossOriginIsolated ? "absent" : "needs cross-origin isolation")) },
  { id: "ua-data", name: "User-Agent Client Hints (JS)", run: async () => {
      if (!navigator.userAgentData) return no("navigator.userAgentData absent");
      const high = await navigator.userAgentData.getHighEntropyValues(["platformVersion", "architecture", "model", "fullVersionList"]);
      return yes(`${navigator.userAgentData.brands.map((b) => b.brand + " " + b.version).join(", ")}; ${high.platform} ${high.platformVersion} ${high.architecture}`);
  } },
  { id: "languages", name: "Languages", run: () => yes(navigator.languages.join(", ")) },
  { id: "time-zone", name: "Time zone", run: () => yes(Intl.DateTimeFormat().resolvedOptions().timeZone) },
  { id: "screen", name: "Screen", run: () => yes(`${screen.width}×${screen.height} @${devicePixelRatio}x, ${screen.colorDepth}-bit, ${matchMedia("(dynamic-range: high)").matches ? "HDR" : "SDR"}, ${matchMedia("(color-gamut: p3)").matches ? "P3" : "sRGB"}`) },
  { id: "hardware", name: "Hardware hints", run: () => yes(`${navigator.hardwareConcurrency} cores, ${navigator.deviceMemory ?? "?"} GB (deviceMemory), ${navigator.maxTouchPoints} touch points`) },
  { id: "dnt", name: "Do Not Track / Global Privacy Control", run: () => yes(`doNotTrack ${navigator.doNotTrack ?? "absent"}, globalPrivacyControl ${navigator.globalPrivacyControl ?? "absent"}`) },
  { id: "webdriver", name: "navigator.webdriver", run: () => (navigator.webdriver ? partial("true: driven by automation") : yes("false")) },
  { id: "pdf", name: "PDF viewer", run: () => (navigator.pdfViewerEnabled ? yes("pdfViewerEnabled") : no(`pdfViewerEnabled ${navigator.pdfViewerEnabled}`)) },
  { id: "plugins", name: "navigator.plugins", run: () => yes(`${navigator.plugins.length}: ${[...navigator.plugins].map((p) => p.name).join(", ")}`) },
]);

// ——— Permissions: their state now, asked of nobody.
const permissionNames = [
  "camera", "microphone", "geolocation", "notifications", "push", "persistent-storage", "clipboard-read", "clipboard-write",
  "midi", "screen-wake-lock", "display-capture", "speaker-selection", "window-management", "local-fonts", "idle-detection",
  "background-sync", "storage-access", "top-level-storage-access", "accelerometer", "gyroscope", "magnetometer",
  "captured-surface-control", "payment-handler", "nfc", "keyboard-lock", "pointer-lock",
];
define("Permissions (state)", permissionNames.map((name) => ({
  id: `permission-${name}`,
  name,
  run: async () => {
    if (!navigator.permissions?.query) return no("navigator.permissions absent");
    try {
      const descriptor = name === "push" ? { name, userVisibleOnly: true } : { name };
      const status = await navigator.permissions.query(descriptor);
      return yes(status.state);
    } catch (error) {
      return no(`not a name this browser knows (${error.name})`);
    }
  },
})));

// ——— Media capture and calls, without a device.
define("Media capture", [
  exists("gum", "getUserMedia", "navigator.mediaDevices.getUserMedia"),
  exists("gdm", "getDisplayMedia", "navigator.mediaDevices.getDisplayMedia"),
  exists("select-audio-output", "selectAudioOutput (speaker picker)", "navigator.mediaDevices.selectAudioOutput"),
  exists("set-sink", "setSinkId (speaker choice)", "HTMLMediaElement.prototype.setSinkId"),
  exists("capture-controller", "CaptureController (focus, zoom of a share)", "CaptureController"),
  exists("crop-target", "CropTarget / RestrictionTarget (share a region)", "CropTarget"),
  exists("media-stream-track-processor", "MediaStreamTrackProcessor (frames of a track)", "MediaStreamTrackProcessor"),
  exists("image-capture", "ImageCapture", "ImageCapture"),
  { id: "devices", name: "Devices (no names before a capture)", run: async () => {
      const list = await navigator.mediaDevices.enumerateDevices();
      const count = (kind) => list.filter((d) => d.kind === kind).length;
      return yes(`${count("videoinput")} cameras, ${count("audioinput")} microphones, ${count("audiooutput")} speakers; names ${list.some((d) => d.label) ? "shown" : "hidden"}`);
  } },
  { id: "constraints", name: "Supported constraints", run: () => yes(Object.keys(navigator.mediaDevices.getSupportedConstraints()).filter((k) => navigator.mediaDevices.getSupportedConstraints()[k]).sort().join(", ")) },
  { id: "canvas-capture", name: "A canvas as a stream (captureStream)", run: () => {
      const canvas = document.createElement("canvas");
      if (!canvas.captureStream) return no("HTMLCanvasElement.captureStream absent");
      const track = canvas.captureStream(30).getVideoTracks()[0];
      track.stop();
      return yes(track.kind);
  } },
  { id: "recorder", name: "MediaRecorder", run: () => (typeof MediaRecorder === "function" ? yes() : no()) },
]);

// ——— WebRTC: two peer connections in the page, no device.
async function loopback(withVideo) {
  const a = new RTCPeerConnection();
  const b = new RTCPeerConnection();
  a.onicecandidate = (e) => e.candidate && b.addIceCandidate(e.candidate);
  b.onicecandidate = (e) => e.candidate && a.addIceCandidate(e.candidate);
  let detail = "";
  const channel = a.createDataChannel("test");
  const opened = new Promise((resolve) => (channel.onopen = resolve));
  const echoed = new Promise((resolve) => {
    b.ondatachannel = (e) => (e.channel.onmessage = (m) => resolve(m.data));
  });
  let canvas, timer;
  const received = withVideo ? new Promise((resolve) => (b.ontrack = resolve)) : null;
  if (withVideo) {
    canvas = Object.assign(document.createElement("canvas"), { width: 320, height: 180 });
    const context = canvas.getContext("2d");
    timer = setInterval(() => { context.fillStyle = `hsl(${Date.now() % 360} 80% 50%)`; context.fillRect(0, 0, 320, 180); }, 33);
    a.addTrack(canvas.captureStream(30).getVideoTracks()[0]);
  }
  await a.setLocalDescription(await a.createOffer());
  await b.setRemoteDescription(a.localDescription);
  await b.setLocalDescription(await b.createAnswer());
  await a.setRemoteDescription(b.localDescription);
  await opened;
  channel.send("ping");
  detail = `data channel echoed "${await echoed}"`;
  if (withVideo) {
    await received;
    await pause(1500);
    let frames = 0, codec = "";
    const stats = await a.getStats();
    stats.forEach((r) => {
      if (r.type === "outbound-rtp" && r.kind === "video") frames = r.framesEncoded ?? 0;
      if (r.type === "codec" && r.mimeType?.startsWith("video/")) codec = r.mimeType;
    });
    detail = `${frames} frames encoded (${codec || "codec unknown"})`;
    clearInterval(timer);
  }
  a.close();
  b.close();
  return detail;
}
define("WebRTC", [
  exists("rtcpc", "RTCPeerConnection", "RTCPeerConnection"),
  { id: "rtc-data", name: "Data channel loopback", run: () => loopback(false), timeout: 10_000 },
  { id: "rtc-video", name: "Video loopback (a canvas)", run: () => loopback(true), timeout: 15_000 },
  { id: "rtc-video-codecs", name: "Video codecs (send)", run: () => yes([...new Set(RTCRtpSender.getCapabilities("video").codecs.map((c) => c.mimeType.replace("video/", "")))].join(", ")) },
  { id: "rtc-audio-codecs", name: "Audio codecs (send)", run: () => yes([...new Set(RTCRtpSender.getCapabilities("audio").codecs.map((c) => c.mimeType.replace("audio/", "")))].join(", ")) },
  exists("rtc-encoded-transform", "Encoded transforms (end-to-end encryption)", "RTCRtpScriptTransform"),
  exists("rtc-insertable", "Insertable streams (Chrome's)", "RTCRtpSender.prototype.createEncodedStreams"),
  exists("webtransport", "WebTransport", "WebTransport"),
]);

// ——— Media formats.
const decoding = async (type, config) => {
  const info = await navigator.mediaCapabilities.decodingInfo({ type: "file", ...config });
  return info.supported ? yes(`${info.smooth ? "smooth" : "not smooth"}, ${info.powerEfficient ? "power efficient" : "not power efficient"}`) : no("not supported");
};
const video = (contentType) => ({ video: { contentType, width: 1920, height: 1080, bitrate: 5_000_000, framerate: 30 } });
const audio = (contentType) => ({ audio: { contentType, channels: "2", bitrate: 128_000, samplerate: 48_000 } });
const play = (type) => {
  const answer = document.createElement("video").canPlayType(type);
  return answer ? yes(answer) : no("\"\"");
};
const encoder = async (codec) => {
  if (!("VideoEncoder" in window)) return no("WebCodecs absent");
  const { supported } = await VideoEncoder.isConfigSupported({ codec, width: 1280, height: 720, bitrate: 2_000_000, framerate: 30 });
  return supported ? yes() : no();
};
define("Media formats", [
  { id: "dec-h264", name: "Decode H.264", run: () => decoding("file", video('video/mp4; codecs="avc1.640028"')) },
  { id: "dec-hevc", name: "Decode HEVC", run: () => decoding("file", video('video/mp4; codecs="hvc1.1.6.L120.90"')) },
  { id: "dec-vp9", name: "Decode VP9", run: () => decoding("file", video('video/webm; codecs="vp09.00.40.08"')) },
  { id: "dec-av1", name: "Decode AV1", run: () => decoding("file", video('video/mp4; codecs="av01.0.08M.08"')) },
  { id: "dec-aac", name: "Decode AAC", run: () => decoding("file", audio('audio/mp4; codecs="mp4a.40.2"')) },
  { id: "dec-opus", name: "Decode Opus", run: () => decoding("file", audio('audio/webm; codecs="opus"')) },
  { id: "dec-flac", name: "Decode FLAC", run: () => decoding("file", audio("audio/flac")) },
  { id: "hls", name: "HLS natively", run: () => play("application/vnd.apple.mpegurl") },
  { id: "mse", name: "Media Source Extensions", run: () => (window.MediaSource || window.ManagedMediaSource ? yes(window.ManagedMediaSource ? "ManagedMediaSource too" : "MediaSource") : no()) },
  { id: "enc-h264", name: "Encode H.264 (WebCodecs)", run: () => encoder("avc1.42001f") },
  { id: "enc-vp9", name: "Encode VP9 (WebCodecs)", run: () => encoder("vp09.00.10.08") },
  { id: "enc-av1", name: "Encode AV1 (WebCodecs)", run: () => encoder("av01.0.04M.08") },
  { id: "enc-hevc", name: "Encode HEVC (WebCodecs)", run: () => encoder("hvc1.1.6.L93.B0") },
  { id: "rec-types", name: "MediaRecorder types", run: () => {
      if (typeof MediaRecorder !== "function") return no("MediaRecorder absent");
      const types = ["video/webm;codecs=vp9,opus", "video/webm;codecs=vp8,opus", "video/webm;codecs=av1", "video/mp4;codecs=avc1,mp4a", "video/mp4", "audio/webm;codecs=opus", "audio/mp4"];
      return yes(types.filter((t) => MediaRecorder.isTypeSupported(t)).join(", ") || "none");
  } },
  { id: "image-types", name: "Images (ImageDecoder)", run: async () => {
      if (!("ImageDecoder" in window)) return skip("ImageDecoder absent: not checked here");
      const types = ["image/avif", "image/webp", "image/jxl", "image/heic", "image/apng"];
      const found = [];
      for (const t of types) if (await ImageDecoder.isTypeSupported(t)) found.push(t.slice(6));
      return yes(found.join(", "));
  } },
  { id: "webp", name: "WebP image", run: () => new Promise((resolve) => {
      const image = new Image();
      image.onload = () => resolve(image.width === 1 ? yes() : no());
      image.onerror = () => resolve(no());
      image.src = "data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA";
  }) },
  { id: "autoplay", name: "Autoplay policy", run: () => (navigator.getAutoplayPolicy ? yes(`media: ${navigator.getAutoplayPolicy("mediaelement")}, audio context: ${navigator.getAutoplayPolicy("audiocontext")}`) : skip("getAutoplayPolicy absent")) },
  exists("eme", "Encrypted Media Extensions (DRM: try it under Asks)", "navigator.requestMediaKeySystemAccess"),
  exists("media-session", "Media Session", "navigator.mediaSession"),
  exists("speech-synthesis", "Speech synthesis", "speechSynthesis"),
  { id: "speech-recognition", name: "Speech recognition", run: () => (window.SpeechRecognition || window.webkitSpeechRecognition ? yes(window.SpeechRecognition ? "SpeechRecognition" : "webkitSpeechRecognition") : no()) },
]);

// ——— Graphics.
define("Graphics", [
  { id: "webgl", name: "WebGL 2", run: () => {
      const gl = document.createElement("canvas").getContext("webgl2");
      if (!gl) return no();
      const info = gl.getExtension("WEBGL_debug_renderer_info");
      return yes(info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER));
  } },
  { id: "webgpu", name: "WebGPU", run: async () => {
      if (!navigator.gpu) return no("navigator.gpu absent");
      const adapter = await navigator.gpu.requestAdapter();
      if (!adapter) return partial("no adapter");
      const info = adapter.info ?? {};
      return yes(`${info.vendor || "?"} ${info.architecture || ""} ${info.description || ""}`.trim());
  } },
  exists("offscreen-canvas", "OffscreenCanvas", "OffscreenCanvas"),
  { id: "canvas-p3", name: "Canvas in Display P3", run: () => (document.createElement("canvas").getContext("2d", { colorSpace: "display-p3" })?.getContextAttributes?.().colorSpace === "display-p3" ? yes() : no()) },
  exists("view-transitions", "View transitions", "document.startViewTransition"),
  css("css-has", ":has()", "selector(:has(a))"),
  css("css-nesting", "CSS nesting", "selector(&)"),
  css("css-container", "Container queries", "container-type: inline-size"),
  css("css-anchor", "Anchor positioning", "anchor-name: --a"),
  css("css-subgrid", "Subgrid", "grid-template-rows: subgrid"),
  css("css-p3", "color(display-p3)", "color: color(display-p3 1 0 0)"),
  css("css-oklch", "oklch()", "color: oklch(70% 0.2 30)"),
  css("css-backdrop", "backdrop-filter", "backdrop-filter: blur(4px)"),
  css("css-scroll-timeline", "Scroll-driven animations", "animation-timeline: scroll()"),
  css("css-text-wrap", "text-wrap: balance", "text-wrap: balance"),
]);

// ——— Storage and workers: written and read back, on this origin only.
define("Storage and workers", [
  { id: "local-storage", name: "localStorage", run: () => { localStorage.setItem("web-tester", "1"); const ok = localStorage.getItem("web-tester") === "1"; localStorage.removeItem("web-tester"); return ok; } },
  { id: "indexeddb", name: "IndexedDB", run: () => new Promise((resolve, reject) => {
      const open = indexedDB.open("web-tester", 1);
      open.onupgradeneeded = () => open.result.createObjectStore("t");
      open.onerror = () => reject(open.error);
      open.onsuccess = () => {
        const db = open.result;
        const store = db.transaction("t", "readwrite").objectStore("t");
        store.put("v", "k");
        const read = store.get("k");
        read.onsuccess = () => { db.close(); indexedDB.deleteDatabase("web-tester"); resolve(read.result === "v"); };
        read.onerror = () => reject(read.error);
      };
  }) },
  { id: "cache-api", name: "Cache API", run: async () => {
      const cache = await caches.open("web-tester");
      await cache.put("/web-tester-probe", new Response("v"));
      const ok = (await (await cache.match("/web-tester-probe")).text()) === "v";
      await caches.delete("web-tester");
      return ok;
  } },
  { id: "opfs", name: "Origin private file system", run: async () => {
      const root = await navigator.storage.getDirectory();
      const handle = await root.getFileHandle("web-tester.txt", { create: true });
      if (!handle.createWritable) return partial("no createWritable (sync access handles in workers only)");
      const writable = await handle.createWritable();
      await writable.write("v");
      await writable.close();
      const ok = (await (await handle.getFile()).text()) === "v";
      await root.removeEntry("web-tester.txt");
      return ok;
  } },
  { id: "quota", name: "Storage quota", run: async () => {
      const { usage, quota } = await navigator.storage.estimate();
      return yes(`${(usage / 1e6).toFixed(1)} MB used of ${(quota / 1e9).toFixed(1)} GB; persisted: ${await navigator.storage.persisted()}`);
  } },
  { id: "cookies", name: "document.cookie", run: () => { document.cookie = "web_tester=1; SameSite=Lax; path=/"; const ok = document.cookie.includes("web_tester=1"); document.cookie = "web_tester=; max-age=0; path=/"; return ok; } },
  { id: "cookie-store", name: "Cookie Store API", run: async () => {
      if (!window.cookieStore) return no("cookieStore absent");
      await cookieStore.set("web_tester_store", "1");
      const ok = (await cookieStore.get("web_tester_store"))?.value === "1";
      await cookieStore.delete("web_tester_store");
      return ok;
  } },
  { id: "worker", name: "Worker", run: () => new Promise((resolve) => {
      const worker = new Worker(URL.createObjectURL(new Blob(["onmessage = (e) => postMessage(e.data * 2)"], { type: "text/javascript" })));
      worker.onmessage = (e) => { worker.terminate(); resolve(e.data === 42); };
      worker.postMessage(21);
  }) },
  exists("shared-worker", "SharedWorker", "SharedWorker"),
  { id: "service-worker", name: "Service worker", run: async () => {
      if (!navigator.serviceWorker) return no("navigator.serviceWorker absent");
      const registration = await navigator.serviceWorker.register("sw.js", { scope: "./sw-scope/" });
      const ok = !!(registration.installing || registration.waiting || registration.active);
      await registration.unregister();
      return ok ? yes("registered and removed") : partial("registered, no worker");
  } },
  { id: "broadcast", name: "BroadcastChannel", run: () => new Promise((resolve) => {
      const a = new BroadcastChannel("web-tester"), b = new BroadcastChannel("web-tester");
      b.onmessage = (e) => { a.close(); b.close(); resolve(e.data === "v"); };
      a.postMessage("v");
  }) },
  { id: "web-locks", name: "Web Locks", run: async () => !!(await navigator.locks.request("web-tester", async () => true)) },
  exists("storage-buckets", "Storage Buckets", "navigator.storageBuckets"),
  exists("file-system-access", "File System Access pickers (try under Asks)", "showOpenFilePicker"),
]);

// ——— Network, through the tester's server.
define("Network", [
  { id: "headers", name: "Headers this browser sends", run: async () => {
      const sent = await (await fetch("/echo", { cache: "no-store" })).json();
      const keep = Object.entries(sent).filter(([k]) => /^(user-agent|accept-language|sec-ch-ua.*|sec-fetch-.*|sec-gpc|dnt|accept-encoding)$/i.test(k));
      return keep.length ? yes(keep.map(([k, v]) => `${k}: ${v}`).join("\n")) : skip("no /echo here: start the tester's server");
  } },
  { id: "sse", name: "Server-sent events", run: () => new Promise((resolve) => {
      const source = new EventSource("/events");
      const seen = [];
      source.onmessage = (e) => { seen.push(e.data); if (seen.length === 3) { source.close(); resolve(yes(seen.join(", "))); } };
      source.onerror = () => { source.close(); resolve(seen.length ? partial(seen.join(", ")) : skip("no /events here")); };
  }) },
  { id: "fetch-stream", name: "Streamed response", run: async () => {
      const reader = (await fetch("/events", { cache: "no-store" })).body.getReader();
      let chunks = 0;
      while (!(await reader.read()).done) chunks += 1;
      return yes(`${chunks} chunks`);
  } },
  { id: "compression", name: "Compression streams", run: async () => {
      const zipped = new Blob(["web tester ".repeat(100)]).stream().pipeThrough(new CompressionStream("gzip"));
      const text = await new Response(zipped.pipeThrough(new DecompressionStream("gzip"))).text();
      return text.length === 1100;
  } },
  { id: "beacon", name: "sendBeacon", run: () => navigator.sendBeacon("/beacon", "web-tester") },
  exists("websocket", "WebSocket", "WebSocket"),
  exists("background-fetch", "Background Fetch", "BackgroundFetchManager"),
]);

// ——— Language and the platform's newer APIs.
define("Platform APIs", [
  exists("structured-clone", "structuredClone", "structuredClone"),
  exists("url-pattern", "URLPattern", "URLPattern"),
  exists("navigation-api", "Navigation API", "navigation"),
  exists("scheduler", "scheduler.postTask", "scheduler.postTask"),
  exists("popover", "Popover", "HTMLElement.prototype.showPopover"),
  exists("dialog", "<dialog>", "HTMLDialogElement"),
  exists("intl-segmenter", "Intl.Segmenter", "Intl.Segmenter"),
  exists("array-from-async", "Array.fromAsync", "Array.fromAsync"),
  exists("set-methods", "Set methods (union…)", "Set.prototype.union"),
  exists("temporal", "Temporal", "Temporal"),
  exists("trusted-types", "Trusted Types", "trustedTypes"),
  exists("sanitizer", "HTML Sanitizer", "Sanitizer"),
  exists("compute-pressure", "Compute Pressure", "PressureObserver"),
  exists("ai-prompt", "Built-in AI (Chrome's LanguageModel)", "LanguageModel"),
  exists("translator", "Translator", "Translator"),
]);

// ——— Device APIs: present or not (each asks under Asks).
define("Devices (present)", [
  exists("web-bluetooth", "Web Bluetooth", "navigator.bluetooth"),
  exists("web-usb", "WebUSB", "navigator.usb"),
  exists("web-hid", "WebHID", "navigator.hid"),
  exists("web-serial", "Web Serial", "navigator.serial"),
  exists("web-midi", "Web MIDI", "navigator.requestMIDIAccess"),
  exists("web-nfc", "Web NFC", "NDEFReader"),
  exists("gamepad", "Gamepad", "navigator.getGamepads"),
  exists("geolocation", "Geolocation", "navigator.geolocation"),
  exists("sensors", "Generic sensors", "Accelerometer"),
  exists("vibrate", "Vibration", "navigator.vibrate"),
  exists("battery", "Battery status", "navigator.getBattery"),
  exists("webauthn", "WebAuthn", "PublicKeyCredential"),
  { id: "passkeys", name: "Passkeys on this device", run: async () => {
      if (!window.PublicKeyCredential) return no();
      const platform = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
      const conditional = await PublicKeyCredential.isConditionalMediationAvailable?.();
      return platform ? yes(`platform authenticator; autofill ${conditional ? "yes" : "no"}`) : partial("no platform authenticator");
  } },
  exists("payment-request", "Payment Request", "PaymentRequest"),
  exists("credential-management", "Federated sign-in (FedCM)", "IdentityCredential"),
  exists("digital-credentials", "Digital credentials", "DigitalCredential"),
  exists("eye-dropper", "EyeDropper", "EyeDropper"),
  exists("idle", "Idle detection", "IdleDetector"),
  exists("local-fonts", "Local fonts", "queryLocalFonts"),
  exists("window-management", "Window management", "getScreenDetails"),
  exists("doc-pip", "Document picture-in-picture", "documentPictureInPicture"),
  exists("wake-lock", "Screen wake lock", "navigator.wakeLock"),
  exists("badging", "App badge", "navigator.setAppBadge"),
  exists("web-share", "Web Share", "navigator.share"),
  exists("contacts", "Contact picker", "navigator.contacts"),
  exists("keyboard-lock", "Keyboard lock", "navigator.keyboard.lock"),
  exists("keyboard-layout", "Keyboard layout map", "navigator.keyboard.getLayoutMap"),
  exists("storage-access", "Storage Access API", "document.requestStorageAccess"),
  exists("protocol-handler", "registerProtocolHandler", "navigator.registerProtocolHandler"),
]);
