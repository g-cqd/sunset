// Every API a page sees, at runtime: each global, and for each interface its static and prototype members, for the
// objects a page reaches through `navigator`, `document`, `window` and friends their own members too. Saved per browser,
// so two browsers can be compared member by member (compare.html, "API inventory").

/** The names an object and its prototypes up to (not including) Object.prototype carry. */
function names(object) {
  const seen = new Set();
  for (let o = object; o && o !== Object.prototype && o !== Function.prototype; o = Object.getPrototypeOf(o)) {
    for (const key of Reflect.ownKeys(o)) {
      if (typeof key === "string") seen.add(key);
    }
  }
  return [...seen].sort();
}

/** The members of an interface: statics, and its prototype's own (not inherited: those are its parents'). */
function members(constructor) {
  const statics = Object.getOwnPropertyNames(constructor).filter((k) => !["length", "name", "prototype", "arguments", "caller"].includes(k));
  const proto = constructor.prototype ? Object.getOwnPropertyNames(constructor.prototype).filter((k) => k !== "constructor") : [];
  return [...statics.map((k) => `static ${k}`), ...proto].sort();
}

/** The inventory: { interfaces: { Name: [members] }, objects: { "navigator": [members] }, globals: [other names] }. */
export function inventory() {
  const interfaces = {};
  const globals = [];
  for (const key of Object.getOwnPropertyNames(globalThis).sort()) {
    let value;
    try {
      value = globalThis[key];
    } catch {
      globals.push(key);
      continue;
    }
    const isInterface = typeof value === "function" && /^[A-Z]/.test(key) && value.prototype !== undefined;
    if (isInterface) {
      interfaces[key] = members(value);
      // A parent, for an interface that inherits (HTMLVideoElement : HTMLMediaElement).
      const parent = Object.getPrototypeOf(value);
      if (parent && parent.name && parent !== Function.prototype) interfaces[key].unshift(`extends ${parent.name}`);
    } else {
      globals.push(key);
    }
  }
  const objects = {};
  const reach = {
    navigator, document, window: globalThis, screen, location, history, performance, crypto,
    "navigator.mediaDevices": navigator.mediaDevices, "navigator.storage": navigator.storage,
    "navigator.permissions": navigator.permissions, "navigator.clipboard": navigator.clipboard,
    "navigator.serviceWorker": navigator.serviceWorker, "navigator.gpu": navigator.gpu,
    "navigator.userAgentData": navigator.userAgentData, "navigator.credentials": navigator.credentials,
    "navigator.mediaSession": navigator.mediaSession, "navigator.wakeLock": navigator.wakeLock,
    "navigator.locks": navigator.locks, "navigator.keyboard": navigator.keyboard,
    CSS: globalThis.CSS, Intl, WebAssembly: globalThis.WebAssembly, Math, Reflect, Atomics: globalThis.Atomics,
    console, speechSynthesis: globalThis.speechSynthesis, caches: globalThis.caches, indexedDB: globalThis.indexedDB,
  };
  for (const [name, object] of Object.entries(reach)) {
    if (object != null) objects[name] = names(object);
  }
  const count = Object.values(interfaces).reduce((n, list) => n + list.length, 0);
  return { interfaces, objects, globals, counts: { interfaces: Object.keys(interfaces).length, members: count, globals: globals.length } };
}

/** Saves the inventory on the tester's server (`/inventory/<label>`). */
export async function saveInventory(label) {
  const body = JSON.stringify({ label, date: new Date().toISOString(), userAgent: navigator.userAgent, ...inventory() });
  try {
    const answer = await fetch(`/inventory/${encodeURIComponent(label)}`, { method: "POST", body, headers: { "content-type": "application/json" } });
    return answer.ok;
  } catch {
    return false;
  }
}
