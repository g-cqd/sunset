document.documentElement.dataset.ext = "content-ran";
chrome.runtime.sendMessage({ hi: true }).then(answer => {
  document.documentElement.dataset.worker = JSON.stringify(answer);
}).catch(error => { document.documentElement.dataset.worker = "error: " + error; });
