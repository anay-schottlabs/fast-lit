// Popup UI: this script runs when the user opens the toolbar popup (see manifest "action").
// It lives in the extension's own origin, not on the web page — so it cannot read the page's DOM directly.

const getDataButton = document.querySelector("#getData");
const injectDataButton = document.querySelector("#injectData");

getDataButton.addEventListener("click", getPageData);
injectDataButton.addEventListener("click", injectDataToFastLit);

async function getPageData() {
    // chrome.tabs.query: asks the browser for open tabs matching filters.
    // "active: true, currentWindow: true" means the tab the user is looking at right now.
    // With the "activeTab" permission, this access is only granted after the user interacts
    // with the extension (e.g. opening this popup or clicking a button).
    const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
    });

    // chrome.scripting.executeScript: runs a function inside the target tab's page.
    // The page's DOM is off-limits from the popup, so we inject a small script to read it.
    // "func" must be a plain function (not a closure over popup variables); Chrome serializes
    // it and runs it in the tab. The return value comes back in results[0].result.
    const results = await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: () => document.documentElement.outerHTML
    });

    const html = results[0].result;

    console.log("Grabbed HTML from page:");
    console.log(html);

    // chrome.storage.local: key-value store private to this extension, persisted on disk.
    // Unlike localStorage on a website, it is not tied to a tab URL and survives browser restarts.
    await chrome.storage.local.set({
        grabbedHtml: html
    });

    console.log("Saved grabbed HTML to local storage.")
}

async function injectDataToFastLit() {
    const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
    });

    // .get accepts key names and returns an object of matching values (undefined if missing).
    const { grabbedHtml } = await chrome.storage.local.get("grabbedHtml");

    if (grabbedHtml) {
        console.log("Successfully loaded grabbed HTML, injecting data.");
        await chrome.scripting.executeScript({
            target: { tabId: tab.id },
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
            args: [grabbedHtml]
        });
    }
    else {
        console.log("Could not load grabbed HTML, cannot inject data.");
    }

}
