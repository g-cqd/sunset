// The tester's core: tests are defined in groups, run (the automatic ones at once, the others from a click), their results
// kept, shown and saved. A test returns what it found; anything it throws is an error, anything that hangs a timeout.
//
// A test: { id, name, kind: "auto" | "ask", run: () => value | Promise<value>, timeout? }
// Its value: true (works), false or undefined (absent), a string (works, with this detail), or { status, detail }.
// Statuses: yes, no, partial, denied (the person or the browser said no), error, timeout, skip.

export const tests = [];
export const results = {};
const listeners = new Set();

export function define(group, list) {
  for (const test of list) tests.push({ kind: "auto", group, ...test });
}

export function onResult(listener) {
  listeners.add(listener);
}

export const yes = (detail = "") => ({ status: "yes", detail });
export const no = (detail = "") => ({ status: "no", detail });
export const partial = (detail = "") => ({ status: "partial", detail });
export const skip = (detail = "") => ({ status: "skip", detail });

/** What a value a test returned says. */
function verdict(value) {
  if (value === true) return yes();
  if (value === false || value === undefined || value === null) return no();
  if (typeof value === "string") return yes(value);
  if (typeof value === "object" && "status" in value) return value;
  return yes(String(value));
}

/** An error as a result: a refusal is "denied", anything else an error. */
function failure(error) {
  const name = error?.name ?? "Error";
  const detail = `${name}: ${error?.message ?? error}`;
  const refused = ["NotAllowedError", "SecurityError", "AbortError"].includes(name);
  return { status: refused ? "denied" : "error", detail };
}

function record(test, result, ms) {
  results[test.id] = { group: test.group, name: test.name, kind: test.kind, ...result, ms: Math.round(ms) };
  for (const listener of listeners) listener(test, results[test.id]);
}

/**
 * Runs a test. Its function is called at once, synchronously, so that a test run from a click keeps the click's user
 * activation (getDisplayMedia, pickers, fullscreen need it; a later microtask may already have lost it in some engines).
 */
export async function run(test) {
  const start = performance.now();
  let pending;
  try {
    pending = test.run();
  } catch (error) {
    record(test, failure(error), performance.now() - start);
    return;
  }
  const limit = test.timeout ?? (test.kind === "ask" ? 120_000 : 5_000);
  let timer;
  const late = new Promise((resolve) => {
    timer = setTimeout(() => resolve({ status: "timeout", detail: `no answer in ${limit / 1000} s` }), limit);
  });
  try {
    const value = await Promise.race([Promise.resolve(pending).then(verdict), late]);
    record(test, value, performance.now() - start);
  } catch (error) {
    record(test, failure(error), performance.now() - start);
  } finally {
    clearTimeout(timer);
  }
}

/** Runs every automatic test, a few at a time. */
export async function runAutomatic(parallel = 6) {
  const queue = tests.filter((t) => t.kind === "auto");
  const workers = Array.from({ length: parallel }, async () => {
    while (queue.length) await run(queue.shift());
  });
  await Promise.all(workers);
}

/** The browser this is: the label it was opened with (`?browser=`), else a guess from what it says it is. */
export function browserLabel() {
  const asked = new URLSearchParams(location.search).get("browser");
  if (asked) return asked;
  const ua = navigator.userAgent;
  if (/Firefox\//.test(ua)) return "firefox";
  if (/Edg\//.test(ua)) return "edge";
  if (/Chrome\//.test(ua)) return "chrome";
  if (/Safari\//.test(ua)) return "safari";
  return "unknown";
}

/** All results, with what the browser says it is. */
export function report() {
  return {
    label: browserLabel(),
    date: new Date().toISOString(),
    url: location.href,
    userAgent: navigator.userAgent,
    brands: navigator.userAgentData?.brands?.map((b) => `${b.brand} ${b.version}`) ?? null,
    platform: navigator.userAgentData?.platform ?? navigator.platform,
    secureContext: window.isSecureContext,
    crossOriginIsolated: window.crossOriginIsolated === true,
    results,
  };
}

/** Saves the results on the tester's server (`/results/<label>`); false where it is not there (a static server). */
export async function save() {
  const body = JSON.stringify(report(), null, 2);
  try {
    const answer = await fetch(`/results/${encodeURIComponent(browserLabel())}`, { method: "POST", body, headers: { "content-type": "application/json" } });
    return answer.ok;
  } catch {
    return false;
  }
}

/** Downloads the results as a file. */
export function download() {
  const blob = new Blob([JSON.stringify(report(), null, 2)], { type: "application/json" });
  const link = Object.assign(document.createElement("a"), { href: URL.createObjectURL(blob), download: `web-tester-${browserLabel()}.json` });
  link.click();
  setTimeout(() => URL.revokeObjectURL(link.href), 1000);
}

/** Waits a moment. */
export const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** The value at a dotted path from `globalThis` ("navigator.mediaDevices.getDisplayMedia"), or undefined. */
export function at(path) {
  return path.split(".").reduce((value, key) => (value == null ? undefined : value[key]), globalThis);
}

/** A test that a global exists. */
export const exists = (id, name, path) => ({ id, name, run: () => (at(path) !== undefined ? yes(path) : no(path)) });
