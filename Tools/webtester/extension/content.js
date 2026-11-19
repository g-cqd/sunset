// On the web tester's pages: asks the background for its probes and gives them to the page, which saves them as it saves
// its own (a background's own request may need a host permission nobody granted, as in a driven Safari).
"use strict";
const contentAPI = globalThis.browser ?? globalThis.chrome;
contentAPI.runtime.sendMessage("results").then((report) => {
  window.postMessage({ source: "web-tester-extension", report }, location.origin);
});
