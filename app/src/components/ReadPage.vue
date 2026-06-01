<script setup>
import { ref, onMounted } from 'vue';
import { Readability } from '@mozilla/readability';

import Reader from './Reader.vue';
import LinedHeader from './LinedHeader.vue';

const toastMessage = ref("");
var toastElement;
var toast;

onMounted(() => {
    toastElement = document.querySelector("#toast");
    toast = Toast.getOrCreateInstance(toastElement);
});

function triggerToast(message) {
    toastMessage.value = message;
    toast.show();
}

// form values
const formText = ref(
    "Welcome to Fast Lit!" +
    " This app uses RSVP, or Rapid Serial Visual Presentation," +
    " a technique that puts one word on the screen at a time." +
    " This means you can focus on the words instead of having to move your eyes around," +
    " making reading a lot faster!" +
    " Plus, this technique also forces you to focus while you're reading," +
    " making sure that you're both finishing the reading material" +
    " and paying attention to what's being said." +
    " In the settings tab above, you can paste in your own text to read," +
    " or use the Fast Lit Grabber extension in your browser to quickly grab articles from webpages and send them right here with one click." +
    " Just install the Fast Lit Grabber extension, open any article or web page you want to read," +
    " and click 'Grab Text' in the extension popup." +
    " Then, click 'Toss Text' in the extension to send the article directly into Fast Lit—no copy and paste required!" +
    " You can also adjust the WPM, which stands for words per minute." +
    " The default here is 300 WPM," +
    " which is already faster than the average reading speed of 250 WPM." +
    " As you practice with this reading technique and use the extension, you'll get better and better at it" +
    " and be able to read faster and faster." +
    " Plus, faster reading speeds help if you're just trying to skim content" +
    " for a quick review." +
    " You'll also notice the red letter in every word." +
    " That's your focal point, which is what you should center your eyes on." +
    " Then, use your peripheral vision to see the rest of the word," +
    " preventing unnecessary movements that could slow you down or make you lose track." +
    " That's all the tips for now, happy reading!"
);
const formWpm = ref(300);

// persistent values
const text = ref(formText.value);
const wpm = ref(formWpm.value);

function updateSettings(showMessage=true) {
    text.value = formText.value;
    wpm.value = formWpm.value;
    if (showMessage) {
        triggerToast("Updated, settings changed");
    }
}

function cancelSettings() {
    formText.value = text.value;
    formWpm.value = wpm.value;
    grabberExtractedText.value = "";
    triggerToast("Canceled, did not update settings");
}

// handling grabber extension

const grabberExtractedText = ref("");
const grabberModalActive = ref(false);

function loadFromGrabber(html) {
    if (grabberModalActive.value) {
        console.log("Received data from extension (Fast Lit Grabber):")
        console.log(html);
        const domParser = new DOMParser();
        const doc = domParser.parseFromString(html, "text/html");
        const article = new Readability(doc).parse();

        if (!article || !article.content) {
            grabberExtractedText.value = "";
            return;
        }

        // Readability gives us clean article HTML in .content.
        // .textContent on that HTML glues block elements together with no space
        // (e.g. "sentence.This" from two <p> tags), which breaks word splitting
        // in the reader. Instead, pull text from each block element separately
        // and join them with blank lines — Reader.parse() collapses that to spaces.

        const articleDoc = domParser.parseFromString(article.content, "text/html");

        const blockTagNames = [
            "p", "h1", "h2", "h3", "h4", "h5", "h6",
            "li", "blockquote", "figcaption"
        ];
        // Compose a CSS selector that matches all the HTML block elements representing "paragraphs" or standalone units of text content in an article
        // This makes a selector string like "p, h1, h2, h3, h4, h5, h6, li, blockquote, figcaption"
        const blockSelector = blockTagNames.join(", ");

        // Use querySelectorAll to get all elements matching those block-level tags from the parsed Readability article HTML
        // This list will typically include all paragraphs, headings, blockquotes, list items, and captions in article order
        const blockElements = articleDoc.body.querySelectorAll(blockSelector);

        // Prepare an array to collect the visible text from each block, respecting internal structure like line breaks within a block
        const textParts = [];

        for (const block of blockElements) {
            // Use innerText (not textContent!) so that explicit line breaks (such as <br> tags inside a paragraph) are preserved as actual line breaks.
            // textContent collapses everything and removes formatting.
            // Example: <p>Hello<br>world</p> -> innerText: "Hello\nworld", textContent: "Helloworld"
            const blockText = block.innerText.trim();

            // Only include the block if there's real content (ignore empty blocks).
            if (blockText.length > 0) {
                textParts.push(blockText);
            }
        }

        // Join all blocks with two newlines ("\n\n") separating them to simulate paragraph breaks.
        // This gives the main Reader robust, space-separated text (Reader.parse() will further collapse multiple breaks to single spaces/paragraphs).
        // The result preserves the original separation between paragraphs, headings, and similar units from the article.
        grabberExtractedText.value = textParts.join("\n\n");
    }
}
window.loadFromGrabber = loadFromGrabber;

var settingsModal;
var grabberModal;

onMounted(() => {
    const settingsModalElement = document.querySelector("#settingsModal");
    const grabberModalElement = document.querySelector("#grabberModal");
    settingsModal = Modal.getOrCreateInstance(settingsModalElement);
    grabberModal = Modal.getOrCreateInstance(grabberModalElement);
});

function openGrabber() {
    settingsModal.hide();
    grabberModal.show();
    updateSettings(false);
    grabberModalActive.value = true;
}

function updateGrab() {
    grabberModal.hide();
    settingsModal.show();
    grabberModalActive.value = false;
    formText.value = grabberExtractedText.value;
    grabberExtractedText.value = "";
    triggerToast("Grabbed article, placed in settings");
}

function cancelGrab() {
    grabberModal.hide();
    settingsModal.show();
    grabberModalActive.value = false;
    grabberExtractedText.value = "";
    triggerToast("Canceled grab, returning to settings");
}
</script>

<template>
    <!-- main page content -->
    <div class="p-5">
        <!-- page header -->
        <div class="mb-5">
            <p class="text-center text-4xl font-bold">Fast Lit</p>
            <button
                class="btn btn-circle btn-ghost absolute top-5 right-5"
                style="background: transparent; box-shadow: none; border: none;"
            >      
                <!-- svg for a gear icon for the settings button -->
                <svg
                    version="1.1"
                    id="Layer_1"
                    xmlns="http://www.w3.org/2000/svg"
                    xmlns:xlink="http://www.w3.org/1999/xlink"
                    x="0px"
                    y="0px"
                    width="32px"
                    height="32px"
                    viewBox="0 0 122.88 122.878"
                    fill="white"
                >
                    <g>
                        <path
                            fill-rule="evenodd"
                            clip-rule="evenodd"
                            d="
                                M101.589,14.7l8.818,8.819c2.321,2.321,2.321,6.118,0,8.439l-7.101,7.101
                                c1.959,3.658,3.454,7.601,4.405,11.752h9.199c3.283,0,5.969,2.686,5.969,5.968V69.25
                                c0,3.283-2.686,5.969-5.969,5.969h-10.039c-1.231,4.063-2.992,7.896-5.204,11.418l6.512,6.51
                                c2.321,2.323,2.321,6.12,0,8.44l-8.818,8.819c-2.321,2.32-6.119,2.32-8.439,0l-7.102-7.102
                                c-3.657,1.96-7.601,3.456-11.753,4.406v9.199c0,3.282-2.685,5.968-5.968,5.968H53.629
                                c-3.283,0-5.969-2.686-5.969-5.968v-10.039c-4.063-1.232-7.896-2.993-11.417-5.205l-6.511,6.512
                                c-2.323,2.321-6.12,2.321-8.441,0l-8.818-8.818c-2.321-2.321-2.321-6.118,0-8.439l7.102-7.102
                                c-1.96-3.657-3.456-7.6-4.405-11.751H5.968C2.686,72.067,0,69.382,0,66.099V53.628
                                c0-3.283,2.686-5.968,5.968-5.968h10.039c1.232-4.063,2.993-7.896,5.204-11.418l-6.511-6.51
                                c-2.321-2.322-2.321-6.12,0-8.44l8.819-8.819c2.321-2.321,6.118-2.321,8.439,0l7.101,7.101
                                c3.658-1.96,7.601-3.456,11.753-4.406V5.969C50.812,2.686,53.498,0,56.78,0h12.471
                                c3.282,0,5.968,2.686,5.968,5.969v10.036c4.064,1.231,7.898,2.992,11.422,5.204l6.507-6.509
                                C95.471,12.379,99.268,12.379,101.589,14.7L101.589,14.7z
                                M61.44,36.92c13.54,0,24.519,10.98,24.519,24.519c0,13.538-10.979,24.519-24.519,24.519
                                c-13.539,0-24.519-10.98-24.519-24.519C36.921,47.9,47.901,36.92,61.44,36.92L61.44,36.92z
                            "
                        />
                  
                    </g>
                </svg>
            </button>
        </div>

        <!-- page body -->
        <Reader :text="text" :wpm="Number(wpm)" />
    </div>

    <!-- settings modal -->
    <div id="settingsModal" class="modal fade" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-scrollable modal-body modal-content h-75">
            <!-- modal header -->
            <div class="modal-header border-0">
                <!-- Close button in top left corner -->
                <button
                    class="btn-close position-absolute start-0 top-0 ms-2 mt-2"
                    @click="cancelSettings"
                    data-bs-dismiss="modal"
                ></button>
          
                <!-- Centered settings text -->
                <div class="col text-center">
                    <span class="fs-2">Settings</span>
                </div>
            </div>

            <!-- modal body -->
            <div class="modal-body">
                <!-- section to choose words per minute of reader -->
                <LinedHeader text="Choose WPM" />
                <div>
                    <input
                        type="range"
                        class="form-range"
                        min="60"
                            max="600"
                        step="10"
                        v-model="formWpm"
                    >
                    <p class="fs-5">{{ formWpm }} words per minute</p>
                </div>
                <!-- section to open grabber modal to interact with extension -->
                <LinedHeader text="Grab Text" />
                <div>
                    <button
                        class="btn btn-secondary"
                        @click="openGrabber"
                    >Use Grabber</button>
                </div>
                <!-- section to manually paste text in -->
                <LinedHeader text="Paste Text" />
                <div>
                    <textarea
                        class="form-control"
                        style="height: 300px;"
                        placeholder="Paste some text to start reading..."
                        v-model="formText"
                    ></textarea>
                </div>
            </div>

            <!-- modal footer -->
            <div class="modal-footer w-100 border-0">
                <div class="d-grid w-100">
                    <button
                        class="btn btn-primary"
                        @click="updateSettings"
                        data-bs-dismiss="modal"
                        :disabled="formText.length == 0"
                    >Update</button>
                </div>
            </div>
        </div>
    </div>

    <!-- grabber modal -->
    <div id="grabberModal" class="modal fade" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-body modal-content h-75">
            <!-- modal header -->
            <div class="modal-header border-0">
                <!-- Close button in top left corner -->
                <button
                    class="btn-close position-absolute start-0 top-0 ms-2 mt-2"
                    @click="cancelGrab"
                ></button>
                <!-- Centered settings text -->
                <div class="col text-center">
                    <span class="fs-2">Grabbing Articles</span>
                </div>
            </div>

            <!-- modal body -->
            <div class="modal-body d-flex flex-column">
                <div>
                    <p class="fs-5">
                        Use the Fast Lit Grabber extension in your browser.
                    </p>
                </div>
                <div class="flex-grow-1">
                    <textarea
                        class="form-control h-100"
                        :value="grabberExtractedText"
                        readonly
                    ></textarea>
                </div>
            </div>

            <!-- modal footer -->
            <div class="modal-footer w-100 border-0">
                <div class="d-grid w-100">
                    <button
                        class="btn btn-primary"
                        @click="updateGrab"
                        :disabled="grabberExtractedText.length == 0"
                    >Update</button>
                </div>
            </div>
        </div>
    </div>

    <!-- toast -->
    <!-- only one toast used for all alerts -->
    <div class="toast-container position-fixed bottom-0 end-0 p-3">
        <div id="toast" class="toast" role="alert">
            <div class="d-flex">
                <div class="toast-body">{{ toastMessage }}</div>
                <button
                    class="btn-close me-2 align-self-center"
                    style="margin-left: auto; margin-right: 0.1rem;"
                    data-bs-dismiss="toast"
                ></button>
          
            </div>
        </div>
    </div>
</template>

<style scoped>
/* prevents textarea from being rescaled */
textarea {
    resize: none;
}
</style>
