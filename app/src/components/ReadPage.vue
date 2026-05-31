<script setup>
import { ref } from 'vue';
import { Readability } from '@mozilla/readability';

import Reader from './Reader.vue';
import LinedHeader from './LinedHeader.vue';

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
  " and can also adjust the WPM, which stands for words per minute." +
  " The default here is 300 WPM," +
  " which is already faster than the average reading speed of 250 WPM." +
  " As you practice with this reading technique over time, you'll get better and better at it" +
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

function updateSettings() {
    text.value = formText.value;
    wpm.value = formWpm.value;
}

function cancelSettings() {
    formText.value = text.value;
    formWpm.value = wpm.value;
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

function openGrabber() {
    updateSettings();
    grabberModalActive.value = true;
}

function updateGrab() {
    grabberModalActive.value = false;
    formText.value = grabberExtractedText.value;
}

function cancelGrab() {
    grabberModalActive.value = false;
    grabberExtractedText.value = "";
}
</script>

<template>
    <!-- main page content -->
    <div class="d-flex flex-column vh-100 p-3">
        <div class="row text-center">
            <div class="d-flex justify-content-center align-items-center">
                <div class="w-100 d-flex align-items-center justify-content-center position-relative">
                    <p class="fs-1 fw-bold m-0 text-center w-100">Fast Lit</p>
                    <i
                        class="ms-3 bi bi-gear fs-4 align-middle btn position-absolute"
                        style="right: 0; vertical-align: middle;"
                        role="img"
                        data-bs-toggle="modal"
                        data-bs-target="#settingsModal"
                    ></i>
                </div>
       
            </div>
   
        </div>
        <div class="row flex-grow-1">
            <div class="col p-1">
                <Reader :text="text" :wpm="Number(wpm)" />
            </div>
        </div>
    </div>

    <!-- settings modal -->
    <div id="settingsModal" class="modal fade" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-scrollable modal-body modal-content h-75">
            <!-- modal header -->
            <div class="modal-header border-0">
                <!-- Close button in top left corner -->
                <button
                    type="button"
                    class="btn position-absolute start-0 top-0 ms-2 mt-2 p-2"
                    data-bs-dismiss="modal"
                    style="z-index:2;"
                    @click="cancelSettings"
                >
                    <i class="bi bi-x-lg fs-4"></i>
                </button>
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
                        data-bs-dismiss="modal"
                        @click="openGrabber"
                        data-bs-toggle="modal"
                        data-bs-target="#grabberModal"
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
                    type="button"
                    class="btn position-absolute start-0 top-0 ms-2 mt-2 p-2"
                    data-bs-dismiss="modal"
                    style="z-index:2;"
                    @click="cancelGrab"
                >
                    <i class="bi bi-x-lg fs-4"></i>
                </button>
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
                        data-bs-dismiss="modal"
                        data-bs-toggle="modal"
                        data-bs-target="#settingsModal"
                    >Update</button>
                </div>
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
