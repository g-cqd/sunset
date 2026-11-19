// The extension's background: on install and on start, runs the probes and saves them on the web tester's server
// (`config.json` names its port; 8767 otherwise). Its popup shows them and saves them again.
/* global probes, runProbes, browserLabel */
"use strict";

// A service worker (Chrome, Safari) loads the probes; a background page (Firefox) has them from the manifest.
if (typeof runProbes === "undefined" && typeof importScripts === "function") importScripts("probes.js");

const extensionAPI = globalThis.browser ?? globalThis.chrome;
let latest = null;

async function port() {
  try {
    return (await (await fetch(extensionAPI.runtime.getURL("config.json"))).json()).port ?? 8767;
  } catch {
    return 8767;
  }
}

async function probeAndSave() {
  const results = await runProbes();
  const label = `${await browserLabel()}-extension`;
  latest = {
    label,
    kind: "extension",
    date: new Date().toISOString(),
    userAgent: navigator.userAgent,
    manifestVersion: extensionAPI.runtime.getManifest().manifest_version,
    results,
  };
  try {
    const answer = await fetch(`http://localhost:${await port()}/results/${label}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(latest),
    });
    latest.saved = answer.ok;
  } catch (error) {
    latest.saved = false;
    latest.saveError = String(error);
  }
  return latest;
}

extensionAPI.runtime.onInstalled?.addListener(() => probeAndSave());
extensionAPI.runtime.onStartup?.addListener(() => probeAndSave());
extensionAPI.runtime.onMessage.addListener((message, _sender, reply) => {
  if (message === "results") {
    (latest ? Promise.resolve(latest) : probeAndSave()).then(reply);
    return true;
  }
  if (message === "probe") {
    probeAndSave().then(reply);
    return true;
  }
  return false;
});
// A background loaded by hand (a WKWebExtension host that does not send onInstalled) probes once too.
setTimeout(() => { if (!latest) probeAndSave(); }, 1500);
