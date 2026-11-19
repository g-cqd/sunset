"use strict";
const extensionAPI = globalThis.browser ?? globalThis.chrome;

function show(report) {
  const values = Object.values(report.results);
  const count = (s) => values.filter((v) => v.status === s).length;
  document.getElementById("summary").textContent =
    `${report.label}: ${count("yes")} yes, ${count("partial")} partly, ${count("denied")} denied, ${count("no")} absent. ` +
    (report.saved ? "Saved on the web tester's server." : "Not saved: is Scripts/web-tester.sh running?");
  const table = document.getElementById("rows");
  table.replaceChildren();
  for (const r of values) {
    const row = table.insertRow();
    row.insertCell().textContent = r.name;
    const status = row.insertCell();
    status.textContent = r.status;
    status.className = r.status;
    row.insertCell().textContent = r.detail;
  }
}

/** Asks the background: every browser's Manifest V3 sendMessage answers with a promise. */
const ask = (message) => extensionAPI.runtime.sendMessage(message);

ask("results").then(show);
document.getElementById("again").onclick = () => {
  document.getElementById("summary").textContent = "Probing…";
  ask("probe").then(show);
};
