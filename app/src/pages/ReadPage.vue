<script setup>
import { ref, useTemplateRef } from 'vue';
import { Readability } from '@mozilla/readability';
import Header from '../components/Header.vue';
import Reader from '../components/Reader.vue';
import { ReadScripts } from '@/assets/textScripts.js';

const minWpm = 60;
const maxWpm = 600;
const wpmStep = 20;

const reader = useTemplateRef("reader");

// form values
const formText = ref(ReadScripts.sampleText);
const formWpm = ref(300);

// persistent values
const text = ref(formText.value);
const wpm = ref(formWpm.value);

// function accessed by Reader.vue to change WPM with arrow keys
function setWpm(newWpm) {
    wpm.value = newWpm;
    formWpm.value = newWpm;
}

// handling settings modal

function openSettings() {
    settingsModal.value = true;
    reader.value.pause();
}

function updateSettings() {
    text.value = formText.value;
    wpm.value = formWpm.value;
    settingsModal.value = false;
}

function loadFromGrabber(html) {
    openSettings();

    console.log("Received data from extension (Fast Lit Grabber):")
    console.log(html);
    const domParser = new DOMParser();
    const doc = domParser.parseFromString(html, "text/html");
    const article = new Readability(doc).parse();

    if (!article || !article.content) {
        formText.value = "";
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
    formText.value = textParts.join("\n\n");
}

// expose this method to the extension
window.loadFromGrabber = loadFromGrabber;

const settingsModal = ref(false);
</script>

<template>
    <Header pageName="Read" />
    
    <!-- main page content -->
    <div class="p-5">
        <div class="mb-5">
            <button
                class="btn btn-circle btn-ghost absolute top-5 right-5"
                @click="openSettings"
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
        <Reader
            ref="reader"
            :text="text"
            :wpm="Number(wpm)"
            :settings-modal="settingsModal"
            :min-wpm="minWpm"
            :max-wpm="maxWpm"
            :wpm-step="wpmStep"
            @set-wpm="setWpm"
        />
    </div>

    <!-- settings modal -->
    <dialog
        class="modal"
        :class="{ 'modal-open': settingsModal }"
    >
        <div class="modal-box bg-deepblue h-7/8 flex flex-col overflow-hidden rounded-3xl border border-white/10 shadow-2xl shadow-black/40">
            <!-- Close button in top left corner -->
            <button
                class="btn btn-circle btn-ghost absolute top-6 left-6 transition-colors hover:bg-white/10"
                @click="updateSettings"
            >
                <svg
                    version="1.1"
                    id="Layer_1"
                    xmlns="http://www.w3.org/2000/svg"
                    xmlns:xlink="http://www.w3.org/1999/xlink"
                    x="0px"
                    y="0px"
                    width="16px"
                    height="16px"
                    viewBox="0 0 122.878 122.88"
                    fill="white"
                >
                    <g>
                        <path
                            d="M1.426,8.313c-1.901-1.901-1.901-4.984,0-6.886c1.901-1.902,4.984-1.902,6.886,0
                            l53.127,53.127l53.127-53.127c1.901-1.902,4.984-1.902,6.887,0c1.901,1.901,1.901,4.985,0,6.886L68.324,61.439
                            l53.128,53.128c1.901,1.901,1.901,4.984,0,6.886c-1.902,1.902-4.985,1.902-6.887,0L61.438,68.326L8.312,121.453
                            c-1.901,1.902-4.984,1.902-6.886,0c-1.901-1.901-1.901-4.984,0-6.886l53.127-53.128L1.426,8.313L1.426,8.313z"
                        />
                    </g>
                </svg>
            </button>

            <!-- Centered header -->
            <div class="text-center mt-1 text-2xl font-bold align-top !text-red">
                <span>Settings</span>
            </div>

            <!-- settings menu -->
            <div class="flex-1 overflow-y-auto px-1">
                <!-- section to choose words per minute of reader -->
                <p class="mb-3 mt-10 text-center text-xs font-semibold uppercase tracking-widest text-white/50">Speed</p>
                <div class="rounded-2xl border border-white/10 bg-white/5 p-5">
                    <input
                        type="range"
                        class="range w-full"
                        :min="minWpm"
                        :max="maxWpm"
                        :step="wpmStep"
                        v-model="formWpm"
                    >
                    <p class="mt-4 text-center">
                        <span class="font-mono text-3xl font-bold !text-red">{{ formWpm }}</span>
                        <span class="text-sm text-white/60"> words per minute</span>
                    </p>
                </div>

                <!-- section to manually paste text in -->
                <p class="mb-3 mt-10 text-center text-xs font-semibold uppercase tracking-widest text-white/50">Paste Text</p>
                <div class="p-1">
                    <textarea
                        class="textarea w-full rounded-2xl border border-white/10 bg-white/5 transition-colors focus:border-red/60 focus:outline-none"
                        style="height: 300px;"
                        placeholder="Paste some text to start reading..."
                        v-model="formText"
                    ></textarea>
                </div>

                <!-- keyboard shortcuts display -->
                <p class="mb-3 mt-10 text-center text-xs font-semibold uppercase tracking-widest text-white/50">Keyboard Shortcuts</p>
                <ul class="list overflow-hidden rounded-2xl border border-white/10 bg-white/5">
                    <!-- play/pause button -->
                    <li class="list-row">
                        <div>
                            <kbd class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow">space</kbd>
                        </div>
                        <div class="list-col-grow flex items-center">
                            <div>Play / Pause</div>
                        </div>
                    </li>

                    <!-- reset button -->
                    <li class="list-row">
                        <div>
                            <span class="inline-flex gap-2">
                                <kbd class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow">r</kbd>
                                <!-- invisible kbd element to take up space so that all text is aligned properly -->
                                <kbd
                                    class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow"
                                    style="visibility: hidden;"
                                ></kbd>
                            </span>
                        </div>
                        <div class="list-col-grow flex items-center">
                            <div>Restart Player</div>
                        </div>
                    </li>

                    <!-- word index controls -->
                    <li class="list-row">
                        <div>
                            <span class="inline-flex gap-2">
                                <kbd class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow">◀︎</kbd>
                                <kbd class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow">▶︎</kbd>
                            </span>
                        </div>
                        <div class="list-col-grow flex items-center">
                            <div>Previous / Next Word</div>
                        </div>
                    </li>

                    <!-- words per minute controls -->
                    <li class="list-row">
                        <div>
                            <span class="inline-flex gap-2">
                                <kbd class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow">▲</kbd>
                                <kbd class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow">▼</kbd>
                            </span>
                        </div>
                        <div class="list-col-grow flex items-center">
                            <div>Increase / Decrease Speed</div>
                        </div>
                    </li>
                </ul>
            </div>

            <!-- button to update changes to settings -->
            <button
                class="mt-5 mx-1 btn-red btn-block !rounded-2xl"
                @click="updateSettings"
                :disabled="formText.length == 0"
            >Update</button>
        </div>
    </dialog>
</template>

<style scoped>
/* prevents textarea from being rescaled */
textarea {
    resize: none;
}
</style>
