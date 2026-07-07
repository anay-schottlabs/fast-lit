<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute } from 'vue-router';
import { db } from '@/firebase/index.js';
import {
    collection,
    getDocs,
    doc,
    updateDoc,
    increment
} from "firebase/firestore";

const totalWordsRead = ref(0);
var docId;
var wordsInSession = 0;

// the list that will be used to play text
// starts out empty, will be filled up by the parse method
const wordList = ref([]);

// the index of the current word in the word list
const wordIndex = ref(0);

// when the value of word index changes, this means the user has read a word
// increment wordsInSession every time a word has been read
watch(wordIndex, (newValue) => {
    // however, if the newValue is zero, this means that the user has reset the reader
    // this happens when the end() method is called
    // the end method, however, is what resets wordsInSession and updates the database
    // therefore, when newValue is reset, we should not increment wordsInSession
    if (newValue != 0) {
        wordsInSession++;
    }
});

async function updateTotalWordsRead() {
    if (wordsInSession > 0) {
        // update counter for total words read
        // this is stored using firebase
        const statsRef = doc(db, "stats", docId);
        await updateDoc(statsRef, {
            totalWordsRead: increment(wordsInSession)
        })
    
        // reset word counter to start next session
        wordsInSession = 0;
    }
}

// get stats from firestore
onMounted(async () => {
    const querySnapshot = await getDocs(collection(db, "stats"));
    querySnapshot.forEach((doc) => {
        docId = doc.id;
        totalWordsRead.value = doc.data().totalWordsRead;
    });
});

const route = useRoute();

// values passed down from ReadPage.vue
const props = defineProps({
    text: String,
    wpm: Number,
    settingsModal: Boolean,
    minWpm: Number,
    maxWpm: Number,
    wpmStep: Number
});

// events sent by Reader.vue to its parent (ReadPage.vue)
const emit = defineEmits([
    "setWpm"
]);

const word = computed(() => {
    return wordList.value[wordIndex.value];
});

const beforeRedLetter = computed(() => {
    return word.value.slice(0, Math.floor(word.value.length / 2));
});

const redLetter = computed(() => {
    return word.value[Math.floor(word.value.length / 2)];
});

const afterRedLetter = computed(() => {
    return word.value.slice(Math.floor(word.value.length / 2) + 1, word.value.length);
});

const interval = computed(() => {
    // Delay (ms) between words, based on wpm passed from App.vue.
    return Math.floor(1000 / (props.wpm / 60));
});

// enum to manage reader states
const PlayState = Object.freeze({
    STOPPED: "stopped",
    PAUSED: "paused",
    PLAYING: "playing"
});

const playState = ref(PlayState.STOPPED);

/**
 * Splits the input text from the textarea into a list of cleaned words.
 *
 * - Trims leading and trailing whitespace from the text.
 * - Inserts a word break after each em dash (—), keeping the dash attached to the preceding word
 *   (e.g. "adulthood—ages" becomes "adulthood—" and "ages").
 * - Replaces all consecutive whitespace characters (spaces, tabs, newlines) within the text with a single space,
 *   ensuring words are separated by only one space.
 *     - Uses the regex /\s+/g, which matches every sequence of one or more whitespace characters (including:
 *         - spaces, tabs (\t), newlines (\n), carriage returns (\r), and other Unicode whitespace)
 *       The global flag 'g' ensures that every such sequence is matched and replaced throughout the string, not just the first one.
 * - Splits the string into an array of individual words using a single space (" ") as the delimiter.
 * - The resulting wordList will be used for sequential display during the speed reading session.
 * - Logs the parsed word list to the console for debugging.
 *
 * Called automatically whenever the textarea text changes.
 */
function parse() {
    // Trim whitespace from both ends of the input text
    let cleanText = props.text.trim();

    // Split at em dashes while keeping the dash on the preceding word
    cleanText = cleanText.replace(/—/g, "— ");

    // Replace any sequence of whitespace characters (spaces, tabs, newlines etc.) with a single space.
    // Regex explanation:
    //   - \s matches any whitespace character.
    //   - + matches one or more of the preceding (i.e., one or more whitespace characters).
    //   - The global flag 'g' replaces all occurrences throughout the string.
    cleanText = cleanText.replace(/\s+/g, " ");

    // Split the resulting string at each single space to create an array of words
    wordList.value = cleanText.split(" ");
    wordIndex.value = 0;
}

watch(() => props.text, parse, { immediate: true });

// global variable to store the ID of the interval
// this is a global var so that it can be accessed by several methods
// the start() method sets the interval and stores the interval's ID
// the pause() and end() methods clear the interval using the stored ID
var readerLoop;

const DelayState = Object.freeze({
    NONE: "none",
    SHORT_PAUSE: "shortPause",
    MEDIUM_PAUSE: "mediumPause",
    LONG_PAUSE: "longPause"
});

const delayState = ref(DelayState.NONE);

// A single tick of the reader loop, extracted out of start() so it can be
// reused when restarting the interval after a mid-playback WPM change (see
// the interval watcher below) without duplicating this logic.
function tick() {
    // Punctuation pauses keep the current word on screen for extra ticks before advancing.
    // Periods use three extra ticks (LONG → MEDIUM → SHORT); commas, em dashes, semicolons, and colons use one (SHORT).

    if (delayState.value == DelayState.LONG_PAUSE) {
        // First extra tick after a period — stay on the same word.
        delayState.value = DelayState.MEDIUM_PAUSE;
        return;
    }
    else if (delayState.value == DelayState.MEDIUM_PAUSE) {
        // Second extra tick after a period — stay on the same word.
        delayState.value = DelayState.SHORT_PAUSE;
        return;
    }
    else if (delayState.value == DelayState.SHORT_PAUSE) {
        // Pause finished — resume normal reading and move to the next word.
        delayState.value = DelayState.NONE;
        if (wordIndex.value >= wordList.value.length - 1) {
            clearInterval(readerLoop);
            playState.value = PlayState.STOPPED;
            return;
        }
        wordIndex.value++;
        return;
    }
    else if (delayState.value == DelayState.NONE) {
        const lastChar = word.value[word.value.length - 1];

        const shortPauseChars = [
            // single short-pause punctuation
            ",",      // comma
            "—",      // em dash
            ";",      // semicolon
            ":",      // colon

            // punctuation followed by closing parenthesis
            ",)",     // comma before closing parenthesis
            ";)",     // semicolon before closing parenthesis
            ":)",     // colon before closing parenthesis

            // punctuation followed by single or double quote
            ",'",     // comma followed by single quote
            ",\"",    // comma followed by double quote
            "—'",     // em dash followed by single quote
            "—\"",    // em dash followed by double quote
            ";'",     // semicolon followed by single quote
            ";\"",    // semicolon followed by double quote
            ":'",     // colon followed by single quote
            ":\"",    // colon followed by double quote
        ];
        const longPauseChars = [
            // single long-pause punctuation
            ".",      // period
            "!",      // exclamation mark
            "?",      // question mark

            // punctuation followed by closing parenthesis
            ".)",     // period before closing parenthesis
            "!)",     // exclamation mark before closing parenthesis
            "?)",     // question mark before closing parenthesis

            // punctuation followed by single or double quote
            ".'",     // period followed by single quote
            ".\"",    // period followed by double quote
            "!'",     // exclamation mark followed by single quote
            "!\"",    // exclamation mark followed by double quote
            "?'",     // question mark followed by single quote
            "?\"",    // question mark followed by double quote
        ];


        if (longPauseChars.includes(lastChar)) {
            // Sentence end — start a long pause without advancing yet.
            delayState.value = DelayState.LONG_PAUSE;
            return;
        }
        else if (shortPauseChars.includes(lastChar)) {
            // Clause break — start a short pause without advancing yet.
            delayState.value = DelayState.SHORT_PAUSE;
            return;
        }

        // No trailing punctuation — advance immediately, or stop at the last word.
        if (wordIndex.value >= wordList.value.length - 1) {
            clearInterval(readerLoop);
            playState.value = PlayState.STOPPED;
            return;
        }
        wordIndex.value++;
    }
}

function start() {
    playState.value = PlayState.PLAYING;
    readerLoop = setInterval(tick, interval.value);
}

// setInterval captures its delay once, so changing wpm mid-playback (e.g. via
// the arrow-key shortcuts) wouldn't otherwise re-pace an already-running
// loop. Restart the interval at the new delay whenever it changes while
// playing, picking up right where wordIndex/delayState left off.
watch(interval, (newInterval) => {
    if (playState.value == PlayState.PLAYING) {
        clearInterval(readerLoop);
        readerLoop = setInterval(tick, newInterval);
    }
});

function pause() {
    playState.value = PlayState.PAUSED;
    clearInterval(readerLoop);
}

defineExpose({
    pause
});

function end() {
    playState.value = PlayState.STOPPED;
    clearInterval(readerLoop);
    wordIndex.value = 0;
    delayState.value = DelayState.NONE;
    updateTotalWordsRead();
}

// event listener for keyboard shortcuts
window.addEventListener('keydown', (event) => {
    if (!props.settingsModal && route.path == "/read") {
        if (event.code == "Space") {
            if (playState.value == PlayState.PLAYING) {
                pause();
            }
            else {
                start();
            }
        }
        else if (event.key == "r") {
            end();
        }
        // WPM can be adjusted regardless of play state — the interval watcher
        // above re-paces an already-running loop, so this works while playing too.
        else if (event.code == "ArrowDown") {
            if (props.wpm != props.minWpm) {
                emit("setWpm", props.wpm - props.wpmStep);
            }
        }
        else if (event.code == "ArrowUp") {
            if (props.wpm != props.maxWpm) {
                emit("setWpm", props.wpm + props.wpmStep);
            }
        }
        else if (playState.value != PlayState.PLAYING) {
            if (event.code == "ArrowLeft") {
                if (wordIndex.value != 0) {
                    wordIndex.value--;
                }
            }
            else if (event.code == "ArrowRight") {
                if (wordIndex.value != wordList.value.length - 1) {
                    wordIndex.value++;
                }
            }
        }
    }
});
</script>

<template>
    <!-- display words per minute -->
    <p class="mt-5 text-center text-lg">
        {{ wpm }} words per minute
    </p>
    
    <!-- main word reader display -->
    <div class="text-7xl font-bold text-center my-30 flex">
        <!-- Shows the part of the word before the highlighted letter, right-aligned within its flex space -->
        <span class="flex-1 text-right">
            {{ beforeRedLetter }}
        </span>
        <!-- Displays the single red-highlighted letter for optimal reading focus -->
        <span class="text-red">
            {{ redLetter }}
        </span>
        <!-- Shows the part of the word after the highlighted letter, left-aligned within its flex space -->
        <span class="flex-1 text-left">
            {{ afterRedLetter }}
        </span>
    </div>

    <!-- progress bar for visual representation of reading progress -->
    <input
        type="range"
        min="0"
        :max="wordList.length - 1"
        v-model="wordIndex"
        class="range w-full mb-10"
        :disabled="playState == PlayState.PLAYING"
        :style="playState == PlayState.PLAYING ? 'opacity: 1; pointer-events: none;' : ''"
    />

    <!-- reader controls section -->
    <div class="flex gap-5 justify-center items-center">
        <!-- button to move to previous word -->
        <button
            class="btn btn-square !text-red bg-white transition-opacity duration-200 opacity-100 hover:opacity-80 disabled:opacity-50"
            :disabled="wordIndex == 0 || playState == PlayState.PLAYING"
            @click="wordIndex--"
            id="previousButton"
            style="width: 3.5rem; height: 3.5rem; min-width: 3.5rem; min-height: 3.5rem;"
        >
            <svg
                viewBox="0 0 64 64"
                width="2.5rem"
                height="2.5rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
            >
                <!-- Larger rounded square background, matching others, radius = 8 -->
                <rect
                    x="6"
                    y="6"
                    width="52"
                    height="52"
                    rx="9"
                    fill="#fff"
                />
                <!-- Larger, thicker left arrow (flip of original) -->
                <polyline
                    points="34,18 20,32 34,46"
                    fill="none"
                    stroke="#E43247"
                    stroke-width="10"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                />
            </svg>
        </button>

        <!-- play button -->
        <button
            class="btn-red !btn-square"
            style="width: 3.5rem; height: 3.5rem; min-width: 3.5rem; min-height: 3.5rem;"
            @click="start"
            id="playButton"
            v-if="playState != PlayState.PLAYING"
        >
  
            <svg
                viewBox="0 0 48 48"
                width="2rem"
                height="2rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
            >
                <path
                    d="M10,8
                       Q8,8 8,10
                       L8,38
                       Q8,40 10,40
                       L38,24
                       Q40,23 38,22
                       Z"
                    fill="#fff"
                />
            </svg>
        </button>

        <!-- pause button -->
        <button
            class="btn-red !btn-square"
            style="width: 3.5rem; height: 3.5rem; min-width: 3.5rem; min-height: 3.5rem;"
            @click="pause"
            id="pauseButton"
            v-if="playState == PlayState.PLAYING"
        >
            <svg
                viewBox="0 0 8 8"
                width="2rem"
                height="2rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
            >
                <g>
                    <!-- Give each bar a rounded radius of 0.5 to match visual style of stop button (proportional: stop uses rx=8 for 48x48 box, so rx=0.5 for 2x6 bar) -->
                    <rect x="1" y="1" width="2" height="6" rx="0.5" fill="#fff" />
                    <rect x="5" y="1" width="2" height="6" rx="0.5" fill="#fff" />
                </g>
            </svg>
        </button>

        <!-- stop/reset button (referred to as "end button") -->
        <button
            class="btn-red !btn-square"
            style="width: 3.5rem; height: 3.5rem; min-width: 3.5rem; min-height: 3.5rem;"
            @click="end"
            id="endButton"
        >
            <svg
                viewBox="0 0 64 64"
                width="2rem"
                height="2rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
            >
                <!-- Rounded square with same r as play (roughly 8 for 2rem button) -->
                <rect
                    x="8"
                    y="8"
                    width="48"
                    height="48"
                    rx="8"
                    fill="#fff"
                />
            </svg>
        </button>

        <!-- button to move to next word -->
        <button
            class="btn btn-square !text-red bg-white transition-opacity duration-200 hover:opacity-80 disabled:opacity-50"
            :disabled="wordIndex == wordList.length - 1 || playState == PlayState.PLAYING"
            @click="wordIndex++"
            id="nextButton"
            style="width: 3.5rem; height: 3.5rem; min-width: 3.5rem; min-height: 3.5rem;"
        >
            <svg
                viewBox="0 0 64 64"
                width="2.5rem"
                height="2.5rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
            >
                <!-- Larger rounded square background, matching others, radius = 8 -->
                <rect
                    x="6"
                    y="6"
                    width="52"
                    height="52"
                    rx="9"
                    fill="#fff"
                />
                <!-- Larger, thicker right arrow -->
                <polyline
                    points="30,18 44,32 30,46"
                    fill="none"
                    stroke="#E43247"
                    stroke-width="10"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                />
            </svg>
        </button>
    </div>
</template>

<style scoped></style>
