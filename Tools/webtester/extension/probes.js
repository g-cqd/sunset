// What a browser's extension APIs do, probed from the extension's background: each namespace and member, present or not,
// and where it can be called without a click, called (written and read back, created and removed). The rows' ids are
// `ext:<namespace>.<member>`, the same as MDN's browser-compat-data (`webextensions.api.<namespace>.<member>`), so the
// documented support can be laid beside the measured one.
/* exported probes, runProbes, browserLabel */
"use strict";

const api = globalThis.browser ?? globalThis.chrome;

/** A member at a dotted path under the extension API, or undefined. */
function member(path) {
  return path.split(".").reduce((value, key) => (value == null ? undefined : value[key]), api);
}

/** Calls an API: as a promise (every browser's Manifest V3 API), else with a callback (an older Chrome one). */
function call(path, ...args) {
  const fn = member(path);
  const owner = member(path.split(".").slice(0, -1).join("."));
  const value = fn.call(owner, ...args);
  if (value && typeof value.then === "function") return value;
  if (value !== undefined) return Promise.resolve(value);
  return new Promise((resolve, reject) => {
    fn.call(owner, ...args, (result) => {
      const error = globalThis.chrome?.runtime?.lastError;
      error ? reject(new Error(error.message)) : resolve(result);
    });
  });
}

/**
 * The probes: [namespace, members]. A member is a name (present or not), or [name, test] where the test calls it and
 * returns a detail.
 */
const probes = [
  ["runtime", [
    ["getManifest", async () => `manifest v${api.runtime.getManifest().manifest_version}`],
    ["getURL", async () => api.runtime.getURL("probes.js").split("/").slice(0, 3).join("/")],
    ["getPlatformInfo", async () => { const p = await call("runtime.getPlatformInfo"); return `${p.os} ${p.arch}`; }],
    ["getBrowserInfo", async () => { const b = await call("runtime.getBrowserInfo"); return `${b.name} ${b.version}`; }],
    "sendMessage", "connect", "onMessage", "onInstalled", "onStartup", "setUninstallURL", "openOptionsPage", "reload",
    ["connectNative", async () => {
      try { await call("runtime.sendNativeMessage", "studio.aemi.no-such-host", {}); return "a host answered"; }
      catch (error) { return `present (no host: ${error.message.slice(0, 60)})`; }
    }],
    "getContexts",
  ]],
  ["storage", [
    ["local", async () => { await call("storage.local.set", { probe: 1 }); const v = await call("storage.local.get", "probe"); await call("storage.local.remove", "probe"); return v.probe === 1 ? "written and read" : "read back wrong"; }],
    ["sync", async () => { await call("storage.sync.set", { probe: 1 }); const v = await call("storage.sync.get", "probe"); await call("storage.sync.remove", "probe"); return v.probe === 1 ? "written and read" : "read back wrong"; }],
    ["session", async () => { await call("storage.session.set", { probe: 1 }); const v = await call("storage.session.get", "probe"); return v.probe === 1 ? "written and read" : "read back wrong"; }],
    ["managed", async () => { try { await call("storage.managed.get"); return "readable"; } catch (e) { return `present (${e.message.slice(0, 50)})`; } }],
    "onChanged",
  ]],
  ["alarms", [
    ["create", async () => { await call("alarms.create", "probe", { delayInMinutes: 60 }); const a = await call("alarms.get", "probe"); await call("alarms.clear", "probe"); return a ? "created and cleared" : "not kept"; }],
    "onAlarm",
  ]],
  ["tabs", [
    ["query", async () => `${(await call("tabs.query", {})).length} tabs`],
    "create", "update", "remove", "sendMessage", "captureVisibleTab", "group", "discard", "onUpdated", "onActivated",
  ]],
  ["windows", [["getAll", async () => `${(await call("windows.getAll", {})).length} windows`], "create"]],
  ["tabGroups", [["query", async () => `${(await call("tabGroups.query", {})).length} groups`]]],
  ["action", [
    ["setBadgeText", async () => { await call("action.setBadgeText", { text: "ok" }); const t = await call("action.getBadgeText", {}); await call("action.setBadgeText", { text: "" }); return `badge "${t}"`; }],
    "setIcon", "setPopup", "openPopup", "onClicked",
  ]],
  ["contextMenus", [["create", async () => { await new Promise((resolve) => api.contextMenus.create({ id: "probe", title: "Probe", contexts: ["page"] }, resolve)); await call("contextMenus.remove", "probe"); return "created and removed"; }]]],
  ["menus", ["create", "getTargetElement"]],
  ["declarativeNetRequest", [
    ["updateDynamicRules", async () => {
      const rule = { id: 4242, priority: 1, action: { type: "block" }, condition: { urlFilter: "||probe.invalid", resourceTypes: ["main_frame"] } };
      await call("declarativeNetRequest.updateDynamicRules", { addRules: [rule], removeRuleIds: [4242] });
      const kept = (await call("declarativeNetRequest.getDynamicRules")).some((r) => r.id === 4242);
      await call("declarativeNetRequest.updateDynamicRules", { removeRuleIds: [4242] });
      return kept ? "a rule added and removed" : "not kept";
    }],
    ["updateSessionRules", async () => { await call("declarativeNetRequest.updateSessionRules", { removeRuleIds: [1] }); return "accepted"; }],
    ["isRegexSupported", async () => JSON.stringify(await call("declarativeNetRequest.isRegexSupported", { regex: "^https://a\\.example/(\\d+)$" }))],
    ["getAvailableStaticRuleCount", async () => `${await call("declarativeNetRequest.getAvailableStaticRuleCount")} static rules left`],
    "MAX_NUMBER_OF_DYNAMIC_RULES", "onRuleMatchedDebug", "testMatchOutcome",
  ]],
  ["webRequest", [
    ["onBeforeRequest", async () => { const listen = () => {}; api.webRequest.onBeforeRequest.addListener(listen, { urls: ["<all_urls>"] }); api.webRequest.onBeforeRequest.removeListener(listen); return "a listener added"; }],
    ["filterResponseData", async () => "present (Firefox's: a response's body)"],
    "onHeadersReceived", "onAuthRequired", "handlerBehaviorChanged",
  ]],
  ["scripting", [
    ["registerContentScripts", async () => {
      await call("scripting.registerContentScripts", [{ id: "probe", matches: ["http://localhost/*"], js: ["probes.js"], persistAcrossSessions: false }]);
      const kept = (await call("scripting.getRegisteredContentScripts")).some((s) => s.id === "probe");
      await call("scripting.unregisterContentScripts", { ids: ["probe"] });
      return kept ? "registered and removed" : "not kept";
    }],
    "executeScript", "insertCSS", "removeCSS",
  ]],
  ["userScripts", [["getScripts", async () => `${(await call("userScripts.getScripts")).length} scripts`], "register", "configureWorld"]],
  ["cookies", [["getAll", async () => `${(await call("cookies.getAll", { domain: "localhost" })).length} on localhost`], "set", "onChanged", "getAllCookieStores"]],
  ["history", [["search", async () => `${(await call("history.search", { text: "", maxResults: 5, startTime: 0 })).length} pages`], "addUrl", "deleteUrl"]],
  ["bookmarks", [["getTree", async () => `${(await call("bookmarks.getTree"))[0]?.children?.length ?? 0} folders at the top`], "create"]],
  ["downloads", [["search", async () => `${(await call("downloads.search", { limit: 5 })).length} downloads`], "download", "open", "onDeterminingFilename"]],
  ["notifications", [["getAll", async () => `${Object.keys(await call("notifications.getAll")).length} shown`], "create"]],
  ["webNavigation", ["getAllFrames", "onCommitted", "onCompleted"]],
  ["idle", [["queryState", async () => await call("idle.queryState", 60)]]],
  ["sessions", [["getRecentlyClosed", async () => `${(await call("sessions.getRecentlyClosed", { maxResults: 5 })).length} closed`], "restore"]],
  ["topSites", [["get", async () => `${(await call("topSites.get")).length} sites`]]],
  ["management", [["getSelf", async () => { const s = await call("management.getSelf"); return `${s.name} (${s.installType})`; }], "getAll"]],
  ["permissions", [["getAll", async () => { const p = await call("permissions.getAll"); return `${p.permissions.length} permissions, ${p.origins.length} origins`; }], "request", "contains"]],
  ["i18n", [["getUILanguage", async () => api.i18n.getUILanguage()], "getMessage", "detectLanguage"]],
  ["commands", [["getAll", async () => `${(await call("commands.getAll")).length} commands`]]],
  ["browsingData", ["remove", "removeCookies", "removeCache"]],
  ["proxy", [["settings", async () => { const s = await call("proxy.settings.get", {}); return `level ${s.levelOfControl}`; }], "onRequest"]],
  ["privacy", [["network", async () => { const s = await call("privacy.network.webRTCIPHandlingPolicy.get", {}); return `WebRTC IP policy ${s.value}`; }], "websites", "services"]],
  ["sidePanel", [["getOptions", async () => JSON.stringify(await call("sidePanel.getOptions", {}))], "open", "setPanelBehavior"]],
  ["sidebarAction", ["open", "setPanel"]],
  ["offscreen", [["hasDocument", async () => `has one: ${await call("offscreen.hasDocument")}`], "createDocument"]],
  ["identity", [["getRedirectURL", async () => api.identity.getRedirectURL().split("/").slice(0, 3).join("/")], "launchWebAuthFlow", "getAuthToken"]],
  ["search", [["get", async () => `${(await call("search.get")).length} engines`], "query", "search"]],
  ["dns", [["resolve", async () => { const r = await call("dns.resolve", "localhost"); return r.addresses.join(", "); }]]],
  ["contextualIdentities", [["query", async () => `${(await call("contextualIdentities.query", {})).length} containers`]]],
  ["theme", [["getCurrent", async () => `theme: ${Object.keys((await call("theme.getCurrent")) ?? {}).length ? "set" : "default"}`]]],
  ["declarativeContent", ["onPageChanged"]],
  ["tts", [["getVoices", async () => `${(await call("tts.getVoices")).length} voices`]]],
  ["fontSettings", [["getFontList", async () => `${(await call("fontSettings.getFontList")).length} fonts`]]],
  ["devtools", ["inspectedWindow", "panels"]],
  ["debugger", ["attach"]],
  ["pageAction", ["show"]],
  ["browserAction", ["setBadgeText"]],
  ["extension", ["getURL", "getViews", "isAllowedIncognitoAccess"]],
  ["webRequestBlocking", []],
];

/** What a background never has, by design: said so (skip), not counted as missing. */
const elsewhere = {
  devtools: "only in a devtools page",
  "devtools.inspectedWindow": "only in a devtools page",
  "devtools.panels": "only in a devtools page",
  pageAction: "Manifest V2 only",
  "pageAction.show": "Manifest V2 only",
  browserAction: "Manifest V2 only (action in V3)",
  "browserAction.setBadgeText": "Manifest V2 only (action in V3)",
  "extension.getURL": "Manifest V2 only (runtime.getURL in V3)",
  webRequestBlocking: "a permission, not a namespace",
};

/** The browser this is, from what the background sees. */
async function browserLabel() {
  if (api.runtime.getBrowserInfo) return "firefox";
  const ua = navigator.userAgent;
  if (/Edg\//.test(ua)) return "edge";
  if (/Chrome\//.test(ua)) return "chrome";
  if (/Version\/[\d.]+ Safari\//.test(ua)) return "safari";
  return "webkit";
}

/** Runs every probe; the results as the web tester keeps them. */
async function runProbes() {
  const results = {};
  for (const [namespace, members] of probes) {
    const group = `Extension: ${namespace}`;
    const base = member(namespace);
    const record = (id, name, status, detail, ms = 0) => (results[id] = { group, name, kind: "auto", status, detail, ms });
    if (elsewhere[namespace] && base === undefined) {
      record(`ext:${namespace}`, namespace, "skip", elsewhere[namespace]);
    } else {
      record(`ext:${namespace}`, namespace, base !== undefined ? "yes" : "no", base !== undefined ? "" : "absent");
    }
    for (const entry of members) {
      const [name, test] = Array.isArray(entry) ? entry : [entry, null];
      const id = `ext:${namespace}.${name}`;
      const label = `${namespace}.${name}`;
      if (base === undefined || member(`${namespace}.${name}`) === undefined) {
        const why = elsewhere[label] ?? elsewhere[namespace];
        if (why) record(id, label, "skip", why);
        else record(id, label, "no", base === undefined ? "namespace absent" : "absent");
        continue;
      }
      if (!test) {
        record(id, label, "yes", "present");
        continue;
      }
      const start = performance.now();
      try {
        const detail = await Promise.race([test(), new Promise((_, reject) => setTimeout(() => reject(new Error("no answer in 5 s")), 5000))]);
        record(id, label, "yes", String(detail ?? ""), performance.now() - start);
      } catch (error) {
        const message = String(error?.message ?? error);
        const denied = /permission|not allowed|denied|unauthori|requires/i.test(message);
        record(id, label, denied ? "denied" : "partial", `present; calling it: ${message.slice(0, 120)}`, performance.now() - start);
      }
    }
  }
  return results;
}
