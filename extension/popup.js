var htmlString;

const getDataButton = document.querySelector("#getData");
const injectDataButton = document.querySelector("#injectData");

getDataButton.addEventListener("click", getPageData);
injectDataButton.addEventListener("click", injectDataToFastLit);

async function getPageData() {
    const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
    });

    const results = await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: () => document.documentElement.outerHTML
    });

    htmlString = results[0].result;

    console.log("Grabbed HTML from page:");
    console.log(htmlString);
}

async function injectDataToFastLit() {
    const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
    });

    await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        world: "MAIN",
        func: (htmlString) => {
            if (window.loadFromGrabber) {
                window.loadFromGrabber(htmlString)
            }
        },
        args: ["test HTML"]
    });
}
