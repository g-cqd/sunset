chrome.runtime.onMessage.addListener((message, sender, reply) => {
  chrome.storage.local.get({ count: 0 }).then(({ count }) => {
    chrome.storage.local.set({ count: count + 1 }).then(() => reply({ count: count + 1, from: "worker" }));
  });
  return true;
});
