// Tests that need a click: each prompts, opens a picker or asks for a device. Run from their button, called at once in the
// click (core.run), so that the browser sees the person's gesture.
import { define, yes, no, partial, skip, pause } from "./core.js";

const stopAll = (stream) => stream.getTracks().forEach((t) => t.stop());
const trackDetail = (stream) => stream.getTracks().map((t) => {
  const s = t.getSettings();
  return `${t.kind} "${t.label}"${s.width ? ` ${s.width}×${s.height}` : ""}${s.displaySurface ? ` (${s.displaySurface})` : ""}`;
}).join("; ");

/** Captures, says what it got, and stops it at once. */
const capture = (promise) => promise.then((stream) => { const detail = trackDetail(stream); stopAll(stream); return yes(detail); });

define("Asks: capture", [
  { id: "ask-camera", kind: "ask", name: "Camera", run: () => capture(navigator.mediaDevices.getUserMedia({ video: true })) },
  { id: "ask-microphone", kind: "ask", name: "Microphone", run: () => capture(navigator.mediaDevices.getUserMedia({ audio: true })) },
  { id: "ask-both", kind: "ask", name: "Camera and microphone", run: () => capture(navigator.mediaDevices.getUserMedia({ video: true, audio: true })) },
  { id: "ask-screen", kind: "ask", name: "Share a screen, window or tab", run: () => capture(navigator.mediaDevices.getDisplayMedia({ video: true })) },
  { id: "ask-screen-audio", kind: "ask", name: "Share with audio", run: () => capture(navigator.mediaDevices.getDisplayMedia({ video: true, audio: true })) },
  { id: "ask-screen-tab", kind: "ask", name: "Share, a tab preferred (Chrome's hints)", run: () => capture(navigator.mediaDevices.getDisplayMedia({ video: { displaySurface: "browser" }, audio: true, selfBrowserSurface: "include", surfaceSwitching: "include", systemAudio: "include" })) },
  { id: "ask-screen-nogesture", kind: "ask", name: "Share after a delay (no gesture left: should be refused)", run: async () => {
      await pause(6000);
      try {
        stopAll(await navigator.mediaDevices.getDisplayMedia({ video: true }));
        return partial("allowed without a gesture");
      } catch (error) {
        return yes(`refused: ${error.name}`);
      }
  } },
  { id: "ask-speaker", kind: "ask", name: "Choose a speaker (selectAudioOutput)", run: async () => {
      if (!navigator.mediaDevices.selectAudioOutput) return no("absent");
      const device = await navigator.mediaDevices.selectAudioOutput();
      return yes(device.label);
  } },
  { id: "ask-device-names", kind: "ask", name: "Device names after a capture", run: async () => {
      stopAll(await navigator.mediaDevices.getUserMedia({ audio: true }));
      const list = await navigator.mediaDevices.enumerateDevices();
      return yes(list.map((d) => `${d.kind}: ${d.label || "(no name)"}`).join("\n"));
  } },
]);

define("Asks: permissions", [
  { id: "ask-geolocation", kind: "ask", name: "Geolocation", run: () => new Promise((resolve, reject) => navigator.geolocation.getCurrentPosition((p) => resolve(yes(`±${Math.round(p.coords.accuracy)} m`)), (e) => reject(Object.assign(new Error(e.message), { name: e.code === 1 ? "NotAllowedError" : "PositionError" })), { timeout: 20000 })) },
  { id: "ask-notification", kind: "ask", name: "Notification", run: async () => {
      const answer = await Notification.requestPermission();
      if (answer !== "granted") return { status: "denied", detail: answer };
      const note = new Notification("Web tester", { body: "A notification", tag: "web-tester" });
      const shown = await Promise.race([new Promise((r) => (note.onshow = () => r(true))), pause(3000).then(() => false)]);
      return shown ? yes("granted, shown") : partial("granted; no show event");
  } },
  { id: "ask-persist", kind: "ask", name: "Persistent storage", run: async () => ((await navigator.storage.persist()) ? yes("persisted") : { status: "denied", detail: "not persisted" }) },
  { id: "ask-midi", kind: "ask", name: "MIDI", run: async () => { const midi = await navigator.requestMIDIAccess(); return yes(`${midi.inputs.size} inputs, ${midi.outputs.size} outputs`); } },
  { id: "ask-storage-access", kind: "ask", name: "Storage access (in a frame of another site: here, at the top)", run: async () => { await document.requestStorageAccess(); return yes("granted (at the top it always is)"); } },
  { id: "ask-idle", kind: "ask", name: "Idle detection", run: async () => yes(await IdleDetector.requestPermission()) },
  { id: "ask-fonts", kind: "ask", name: "Local fonts", run: async () => yes(`${(await queryLocalFonts()).length} fonts`) },
  { id: "ask-screens", kind: "ask", name: "Window management (screens)", run: async () => { const details = await getScreenDetails(); return yes(details.screens.map((s) => `${s.label || "screen"} ${s.width}×${s.height}`).join(", ")); } },
]);

define("Asks: clipboard", [
  { id: "ask-clip-write", kind: "ask", name: "Write text", run: async () => { await navigator.clipboard.writeText("web tester"); return yes(); } },
  { id: "ask-clip-read", kind: "ask", name: "Read text", run: async () => yes(JSON.stringify((await navigator.clipboard.readText()).slice(0, 60))) },
  { id: "ask-clip-image", kind: "ask", name: "Write an image", run: async () => {
      const canvas = Object.assign(document.createElement("canvas"), { width: 8, height: 8 });
      canvas.getContext("2d").fillRect(0, 0, 8, 8);
      const blob = await new Promise((r) => canvas.toBlob(r, "image/png"));
      await navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
      return yes("image/png");
  } },
  { id: "ask-clip-items", kind: "ask", name: "Read items", run: async () => yes((await navigator.clipboard.read()).flatMap((i) => i.types).join(", ")) },
]);

define("Asks: files and sharing", [
  { id: "ask-open-file", kind: "ask", name: "Open a file (showOpenFilePicker)", run: async () => { const [h] = await showOpenFilePicker(); const f = await h.getFile(); return yes(`${f.name}, ${f.size} bytes`); } },
  { id: "ask-save-file", kind: "ask", name: "Save a file (showSaveFilePicker)", run: async () => { const h = await showSaveFilePicker({ suggestedName: "web-tester.txt" }); const w = await h.createWritable(); await w.write("web tester\n"); await w.close(); return yes(h.name); } },
  { id: "ask-folder", kind: "ask", name: "Open a folder (showDirectoryPicker)", run: async () => { const h = await showDirectoryPicker(); let n = 0; for await (const _ of h.values()) n += 1; return yes(`${h.name}: ${n} entries`); } },
  { id: "ask-input-file", kind: "ask", name: "Open a file (<input type=file>)", run: () => new Promise((resolve) => {
      const input = Object.assign(document.createElement("input"), { type: "file", multiple: true });
      input.onchange = () => resolve(yes([...input.files].map((f) => `${f.name} (${f.size} bytes)`).join(", ")));
      input.oncancel = () => resolve({ status: "denied", detail: "cancelled" });
      input.click();
  }) },
  { id: "ask-download", kind: "ask", name: "Download a file (<a download>)", run: () => {
      const link = Object.assign(document.createElement("a"), { href: URL.createObjectURL(new Blob(["web tester\n"], { type: "text/plain" })), download: "web-tester.txt" });
      link.click();
      return yes("asked: see the browser's downloads");
  } },
  { id: "ask-share", kind: "ask", name: "Web Share", run: async () => { await navigator.share({ title: "Web tester", text: "A test", url: location.href }); return yes("shared"); } },
  { id: "ask-eyedropper", kind: "ask", name: "EyeDropper", run: async () => yes((await new EyeDropper().open()).sRGBHex) },
]);

define("Asks: devices", [
  { id: "ask-bluetooth", kind: "ask", name: "Bluetooth device", run: async () => yes((await navigator.bluetooth.requestDevice({ acceptAllDevices: true })).name) },
  { id: "ask-usb", kind: "ask", name: "USB device", run: async () => yes((await navigator.usb.requestDevice({ filters: [] })).productName) },
  { id: "ask-hid", kind: "ask", name: "HID device", run: async () => yes((await navigator.hid.requestDevice({ filters: [] })).map((d) => d.productName).join(", ") || "none chosen") },
  { id: "ask-serial", kind: "ask", name: "Serial port", run: async () => { const port = await navigator.serial.requestPort(); return yes(JSON.stringify(port.getInfo())); } },
  { id: "ask-gamepad", kind: "ask", name: "Gamepad (press a button within 10 s)", run: () => new Promise((resolve) => {
      addEventListener("gamepadconnected", (e) => resolve(yes(e.gamepad.id)), { once: true });
      setTimeout(() => resolve(skip("none pressed")), 10000);
  }) },
  { id: "ask-passkey-create", kind: "ask", name: "Create a passkey (localhost)", run: async () => {
      const credential = await navigator.credentials.create({ publicKey: {
        challenge: crypto.getRandomValues(new Uint8Array(32)),
        rp: { name: "Web tester", id: location.hostname },
        user: { id: crypto.getRandomValues(new Uint8Array(16)), name: "tester@localhost", displayName: "Tester" },
        pubKeyCredParams: [{ type: "public-key", alg: -7 }, { type: "public-key", alg: -257 }],
        authenticatorSelection: { residentKey: "preferred", userVerification: "preferred" },
        timeout: 60000,
      } });
      return yes(`${credential.type}, ${credential.authenticatorAttachment ?? "attachment unknown"}`);
  } },
  { id: "ask-passkey-get", kind: "ask", name: "Sign in with a passkey (localhost)", run: async () => {
      const credential = await navigator.credentials.get({ publicKey: { challenge: crypto.getRandomValues(new Uint8Array(32)), rpId: location.hostname, userVerification: "preferred", timeout: 60000 } });
      return yes(credential.type);
  } },
  { id: "ask-drm", kind: "ask", name: "DRM key systems", run: async () => {
      const config = [{ initDataTypes: ["cenc", "sinf", "skd"], videoCapabilities: [{ contentType: 'video/mp4; codecs="avc1.42E01E"' }] }];
      const found = [];
      for (const system of ["com.apple.fps", "com.apple.fps.1_0", "com.widevine.alpha", "org.w3.clearkey", "com.microsoft.playready"]) {
        try { await navigator.requestMediaKeySystemAccess(system, config); found.push(system); } catch {}
      }
      return found.length ? yes(found.join(", ")) : no("none");
  } },
  { id: "ask-payment", kind: "ask", name: "Payment Request (can it pay)", run: async () => {
      const request = new PaymentRequest([{ supportedMethods: "https://apple.com/apple-pay", data: { version: 3, merchantIdentifier: "test", merchantCapabilities: ["supports3DS"], supportedNetworks: ["visa"], countryCode: "US" } }], { total: { label: "Test", amount: { currency: "USD", value: "0.01" } } });
      return yes(`canMakePayment: ${await request.canMakePayment()}`);
  } },
]);

define("Asks: windows and pages", [
  { id: "ask-fullscreen", kind: "ask", name: "Full screen (Esc leaves)", run: async () => { await document.documentElement.requestFullscreen(); await pause(1500); await document.exitFullscreen(); return yes("entered and left"); } },
  { id: "ask-video-fullscreen", kind: "ask", name: "A video in full screen", run: async () => {
      const canvas = Object.assign(document.createElement("canvas"), { width: 320, height: 180 });
      const context = canvas.getContext("2d");
      const video = Object.assign(document.createElement("video"), { muted: true, autoplay: true, playsInline: true });
      video.srcObject = canvas.captureStream(30);
      const timer = setInterval(() => { context.fillStyle = `hsl(${Date.now() % 360} 70% 50%)`; context.fillRect(0, 0, 320, 180); }, 33);
      document.body.append(video);
      await video.play();
      await video.requestFullscreen();
      await pause(2000);
      await document.exitFullscreen();
      clearInterval(timer);
      video.remove();
      return yes("shown for 2 s: did it draw?");
  } },
  { id: "ask-pip", kind: "ask", name: "Picture in picture", run: async () => {
      const canvas = Object.assign(document.createElement("canvas"), { width: 320, height: 180 });
      canvas.getContext("2d").fillRect(0, 0, 320, 180);
      const video = Object.assign(document.createElement("video"), { muted: true, autoplay: true });
      video.srcObject = canvas.captureStream(1);
      document.body.append(video);
      await video.play();
      await video.requestPictureInPicture();
      await pause(1500);
      await document.exitPictureInPicture();
      video.remove();
      return yes("opened and closed");
  } },
  { id: "ask-doc-pip", kind: "ask", name: "Document picture-in-picture", run: async () => { const w = await documentPictureInPicture.requestWindow({ width: 300, height: 200 }); w.document.body.textContent = "Web tester"; await pause(1500); w.close(); return yes(); } },
  { id: "ask-wake", kind: "ask", name: "Keep the screen on", run: async () => { const lock = await navigator.wakeLock.request("screen"); await pause(1000); await lock.release(); return yes("held 1 s"); } },
  { id: "ask-pointer-lock", kind: "ask", name: "Pointer lock (Esc leaves)", run: async () => { await document.body.requestPointerLock(); await pause(1000); document.exitPointerLock(); return yes(); } },
  { id: "ask-keyboard-lock", kind: "ask", name: "Keyboard lock (in full screen)", run: async () => { await document.documentElement.requestFullscreen(); await navigator.keyboard.lock(["Escape"]); await pause(1500); navigator.keyboard.unlock(); await document.exitFullscreen(); return yes(); } },
  { id: "ask-popup", kind: "ask", name: "Open a window (window.open)", run: () => { const w = open("about:blank", "web-tester", "width=400,height=300"); if (!w) return { status: "denied", detail: "blocked" }; setTimeout(() => w.close(), 1500); return yes("opened"); } },
  { id: "ask-popup-nogesture", kind: "ask", name: "Open a window after a delay (should be blocked)", run: async () => { await pause(6000); const w = open("about:blank", "web-tester-late"); if (w) { w.close(); return partial("opened without a gesture"); } return yes("blocked"); } },
  { id: "ask-alert", kind: "ask", name: "alert, confirm, prompt", run: () => { alert("Web tester: alert"); const c = confirm("Web tester: confirm?"); const p = prompt("Web tester: prompt", "default"); return yes(`confirm ${c}, prompt ${JSON.stringify(p)}`); } },
  { id: "ask-print", kind: "ask", name: "Print", run: () => { print(); return yes("asked"); } },
  { id: "ask-vibrate", kind: "ask", name: "Vibrate", run: () => (navigator.vibrate?.(200) ? yes() : no("refused or absent")) },
  { id: "ask-speak", kind: "ask", name: "Speak", run: () => new Promise((resolve) => {
      const utterance = new SpeechSynthesisUtterance("Web tester");
      utterance.onend = () => resolve(yes(`${speechSynthesis.getVoices().length} voices`));
      utterance.onerror = (e) => resolve({ status: "error", detail: e.error });
      speechSynthesis.speak(utterance);
  }) },
  { id: "ask-listen", kind: "ask", name: "Speech recognition (say something)", run: () => new Promise((resolve, reject) => {
      const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!Recognition) return resolve(no());
      const r = new Recognition();
      r.onresult = (e) => resolve(yes(e.results[0][0].transcript));
      r.onerror = (e) => reject(Object.assign(new Error(e.error), { name: e.error === "not-allowed" ? "NotAllowedError" : "Error" }));
      r.start();
  }) },
  { id: "ask-badge", kind: "ask", name: "App badge", run: async () => { await navigator.setAppBadge(3); await pause(1500); await navigator.clearAppBadge(); return yes(); } },
  { id: "ask-protocol", kind: "ask", name: "Register a protocol handler", run: () => { navigator.registerProtocolHandler("web+tester", `${location.origin}/?handled=%s`); return yes("asked"); } },
]);
