// Popup UI: this script runs when the user opens the toolbar popup (see manifest "action").
// It lives in the extension's own origin, not on the web page — so it cannot read the page's DOM directly.

const getDataButton = document.querySelector("#getData");
const injectDataButton = document.querySelector("#injectData");

getDataButton.addEventListener("click", getPageData);
injectDataButton.addEventListener("click", injectDataToFastLit);

// message content for the text boxes
const grabInfo = "Copy from this page.";
const injectInfo = "Send copied article to Fast Lit.";

const grabInfoDetailed =
    "Click 'Grab' to quickly extract the main article from this tab. "
  + "We will retrieve the most relevant content from the page you are viewing, "
  + "so you can send it to the Fast Lit site and start reading.";

const injectInfoDetailed =
    "First, in Fast Lit, select 'Use Grabber' and keep that window open. "
  + "Then return here and click 'Send to Reader' to transfer your grabbed article. "
  + "This provides a simple and efficient way to read and highlight content in Fast Lit.";

const grabSuccess = "Grabbed article from [url] at [time].";
const injectSuccess = "Sent article to Fast Lit at [time].";

const grabTextarea = document.querySelector("#grabTextarea");
const injectTextarea = document.querySelector("#injectTextarea");

const grabAccordion = document.querySelector("#grabAccordion");
const injectAccordion = document.querySelector("#injectAccordion");

grabAccordion.innerHTML = grabInfoDetailed;
injectAccordion.innerHTML = injectInfoDetailed;

// automatically change the height of the textarea based on its content
function scaleTextarea(textarea) {
    textarea.style.height = "1px";
    textarea.style.height = (textarea.scrollHeight) + "px";
}

(async () => {
    // Helper to check if two dates are the same calendar day
    function isSameDay(d1, d2) {
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate();
    }

    const storageData = await chrome.storage.local.get([
        'grabbedUrl',
        'grabbedDateTime',
        'grabbedTimeDisplay'
    ]);

    const now = new Date();
    let textareaMsg = grabInfo;

    if (
        storageData.grabbedUrl &&
        storageData.grabbedDateTime &&
        storageData.grabbedTimeDisplay
    ) {
        const grabbedDate = new Date(storageData.grabbedDateTime);
        if (isSameDay(now, grabbedDate)) {
            textareaMsg = grabSuccess
                .replace("[url]", storageData.grabbedUrl)
                .replace("[time]", storageData.grabbedTimeDisplay);
        }
    }

    grabTextarea.innerHTML = textareaMsg;
    injectTextarea.innerHTML = injectInfo;

    scaleTextarea(grabTextarea);
    scaleTextarea(injectTextarea);
})();

async function getPageData() {
    // chrome.tabs.query: asks the browser for open tabs matching filters.
    // "active: true, currentWindow: true" means the tab the user is looking at right now.
    // With the "activeTab" permission, this access is only granted after the user interacts
    // with the extension (e.g. opening this popup or clicking a button).
    const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
    });

    // Use XMLSerializer to serialize the DOM to an HTML string in the page context.
    const results = await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: () => {
            // Use XMLSerializer for HTML serialization
            return new XMLSerializer().serializeToString(document.documentElement);
        }
    });

    const html = results[0].result;

    console.log("Grabbed HTML from page using XMLSerializer:");
    console.log(html);

    // chrome.storage.local: key-value store private to this extension, persisted on disk.
    // Unlike localStorage on a website, it is not tied to a tab URL and survives browser restarts.
    await chrome.storage.local.set({
        grabbedHtml: html
    });

    console.log("Saved grabbed HTML to local storage.")

    // Store url, date and time in chrome local storage
    const pageUrl = new URL(tab.url);
    const baseUrl = `${pageUrl.protocol}//${pageUrl.host}`;
    const now = new Date();
    const timeString = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    // Save url, date, and time to local storage
    await chrome.storage.local.set({
        grabbedUrl: baseUrl,
        grabbedDateTime: now.toISOString(),
        grabbedTimeDisplay: timeString
    });
    grabTextarea.innerHTML = grabSuccess.replace("[url]", baseUrl).replace("[time]", timeString);

    scaleTextarea(grabTextarea);
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

    injectTextarea.innerHTML = injectSuccess
        .replace(
            "[time]", 
            new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        );
    
    scaleTextarea(injectTextarea);
}
