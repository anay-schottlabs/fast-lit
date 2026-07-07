const grabButton = document.querySelector("#grabButton");
const grabButtonIcon = grabButton.querySelector(".btn-icon");
const grabButtonSpinner = grabButton.querySelector(".spinner-border");
const grabButtonLabel = grabButton.querySelector(".btn-label");

grabButton.addEventListener("click", grab);

async function grab() {
    setLoading(true);

    try {
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
                const documentClone = document.cloneNode(true);
                return new XMLSerializer().serializeToString(documentClone);
            }
        });

        const grabbedHtml = results[0].result;

        chrome.runtime.sendMessage({
            action: "openFastLit",
            html: grabbedHtml
        });
    } catch (error) {
        console.error("Fast Lit: failed to grab the page.", error);
    } finally {
        setLoading(false);
    }
}

function setLoading(isLoading) {
    grabButton.disabled = isLoading;
    grabButtonIcon.classList.toggle("d-none", isLoading);
    grabButtonSpinner.classList.toggle("d-none", !isLoading);
    grabButtonLabel.textContent = isLoading ? "Grabbing…" : "Grab Article";
}
