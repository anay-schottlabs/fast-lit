var html;

const getDataButton = document.querySelector("#getData");
const injectDataButton = document.querySelector("#injectData");

getDataButton.addEventListener("click", getPageData);
injectDataButton.addEventListener("click", injectDataToFastLib);

async function getPageData() {
    const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
    });

    const results = await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: () => document.documentElement.outerHTML
    });

    html = results[0].result;
    console.log(html);
}

async function injectDataToFastLib() {
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
        args: [html]
    });
}
