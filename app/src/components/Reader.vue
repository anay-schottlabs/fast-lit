<script setup>
import { ref, computed, watch } from 'vue';

// text in the textarea is passed down from App.vue
const props = defineProps({
    text: String,
    wpm: Number
});

// the list that will be used to play text
// starts out empty, will be filled up by the parse method
const wordList = ref([]);

// the index of the current word in the word list
const wordIndex = ref(0);

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

const isOnLastWord = computed(() => wordIndex.value == wordList.value.length - 1);

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

function start() {
    playState.value = PlayState.PLAYING;
    readerLoop = setInterval(() => {
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
    }, interval.value);
}

function pause() {
    playState.value = PlayState.PAUSED;
    clearInterval(readerLoop);
}

function end() {
    playState.value = PlayState.STOPPED;
    clearInterval(readerLoop);
    wordIndex.value = 0;
    delayState.value = DelayState.NONE;
}
</script>

<template>
    <!-- Reader Controls Section -->
    <div class="flex gap-5">
        <!-- 
            Start/Continue Button:
            - Visible when the reader is stopped and not at the last word (initial state or after hitting "End"), or paused.
            - Shows "Start Reader" if never started or after ending, or "Continue Reader" if paused.
        -->
        <button
            v-if="(playState == PlayState.STOPPED && !isOnLastWord) || playState == PlayState.PAUSED"
            class="btn bg-red grow transition-opacity duration-200"
            :class="{
                'opacity-100 hover:opacity-80': playState == PlayState.STOPPED || playState == PlayState.PAUSED
            }"
            @click="start"
        >
            {{ playState == PlayState.PAUSED ? "Continue Reader" : "Start Reader" }}
        </button>
 
 

        <!-- 
            Pause Button:
            - Visible only when the reader is actively playing.
            - Lets the user pause the reading session.
        -->
        <button
            v-if="playState == PlayState.PLAYING"
            class="btn bg-red grow transition-opacity duration-200"
            :class="{'opacity-100 hover:opacity-80': playState == PlayState.PLAYING}"
            @click="pause"
        >
  
  
            Pause Reader
        </button>

        <!-- 
            End/Restart Button:
            - Visible while playing, paused, or when on the last word.
            - Shows "End Reader" during play or pause, or "Restart Reader" at the last word.
        -->
        <button
            v-if="playState != PlayState.STOPPED || isOnLastWord"
            class="btn bg-red grow transition-opacity duration-200"
            :class="{
                'opacity-100 hover:opacity-80': playState != PlayState.STOPPED || isOnLastWord
            }"
            @click="end"
        >
            {{ isOnLastWord ? "Restart Reader" : "End Reader" }}
        </button>
 
    </div>

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


    <!-- Controls to manually move through word list -->
    <div class="flex gap-5 mb-5">
        <!-- button to move to previous word -->
        <button
            class="btn !text-red bg-white transition-opacity duration-200 grow"
            :class="{
                'opacity-50': wordIndex == 0,
                'opacity-100 hover:opacity-80': wordIndex !== 0
            }"
            :disabled="wordIndex == 0 || playState == PlayState.PLAYING"
            @click="wordIndex--"
        >Previous</button>
        <!-- button to move to next word -->
        <button
            class="btn !text-red bg-white transition-opacity duration-200 grow"
            :class="{
                'opacity-50': wordIndex == wordList.length - 1,
                'opacity-100 hover:opacity-80': wordIndex !== wordList.length - 1
            }"
            :disabled="wordIndex == wordList.length - 1 || playState == PlayState.PLAYING"
            @click="wordIndex++"
        >Next</button>
    </div>

    <!-- progress bar for visual representation of reading progress -->
    <input
        type="range"
        min="0"
        :max="wordList.length - 1"
        v-model="wordIndex"
        class="range w-full"
        :disabled="playState == PlayState.PLAYING"
        :style="playState == PlayState.PLAYING ? 'opacity: 1; pointer-events: none;' : ''"
    />
</template>

<style scoped></style>
