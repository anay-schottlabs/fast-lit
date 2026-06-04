chrome.runtime.onMessage.addListener(
    async (message, sender, sendResponse) => {
        if (message.action == "openFastLit") {
            // Create the new tab
            const tab = await new Promise(resolve => {
                chrome.tabs.create({
                    url: "https://fastlit.netlify.app/read"
                }, resolve);
            });

            const fastLitTabId = tab.id;

            // Wait until the tab is fully loaded before injecting
            await new Promise(resolve => {
                function handleUpdated(tabId, info) {
                    if (tabId === fastLitTabId && info.status === "complete") {
                        chrome.tabs.onUpdated.removeListener(handleUpdated);
                        resolve();
                    }
                }
                chrome.tabs.onUpdated.addListener(handleUpdated);
            });

            // Inject grabbed html
            await chrome.scripting.executeScript({
                target: { tabId: fastLitTabId },
                // By default, injected scripts run in an "isolated" JavaScript world: same DOM as the
                // page, but separate window object — so page scripts like window.loadFromGrabber are
                // invisible. world: "MAIN" runs in the page's own JS context so we can call site code.
                world: "MAIN",
                func: (html) => {
                    if (window.loadFromGrabber) {
                        window.loadFromGrabber(html);
                    }
                },
                // args are cloned and passed into func in the target tab (must be JSON-serializable).
                args: [message.html]
            });
        }
    }
);
