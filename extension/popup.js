const grabButton = document.querySelector("#grabButton");
grabButton.addEventListener("click", grab);

const infoText = document.querySelector("#infoText");
infoText.innerHTML = [
    "Go to the page of an article you want to read, and then open this extension.",
    "Pressing the 'grab' button automatically finds readable content on the page,",
    "opens the Fast Lit website, and sets up all the content inside so you can start reading right away.",
    "In Fast Lit, just hit the 'update' button to get started."
].join(" ");

async function grab() {
    // chrome.tabs.query: asks the browser for open tabs matching filters.
    // "active: true, currentWindow: true" means the tab the user is looking at right now.
    // With the "activeTab" permission, this access is only granted after the user interacts
    // with the extension (e.g. opening this popup or clicking a button).
    const [grabTab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
    });

    // Use XMLSerializer to serialize the DOM to an HTML string in the page context.
    const results = await chrome.scripting.executeScript({
        target: { tabId: grabTab.id },
        func: () => {
            // Use XMLSerializer for HTML serialization
            return new XMLSerializer().serializeToString(document.documentElement);
        }
    });

    const grabbedHtml = results[0].result;

    chrome.runtime.sendMessage({
        action: "openFastLit",
        html: grabbedHtml
    });
}
