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

            if ([".", "!", "?"].includes(lastChar)) {
       
                // Sentence end — start a long pause without advancing yet.
                delayState.value = DelayState.LONG_PAUSE;
                return;
            }
            else if ([",", "—", ";", ":"].includes(lastChar)) {
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
    <div class="d-flex flex-column">

        <!-- Reader Controls Section -->
        <div class="btn-group mb-5">
            <!-- Show "Start/Continue Reader" if NOT currently playing -->
            <button
                class="btn btn-primary"
                v-if="(playState == PlayState.STOPPED && !isOnLastWord) || playState == PlayState.PAUSED"
                @click="start"
            >
                {{ playState == PlayState.PAUSED ? "Continue Reader" : "Start Reader" }}
            </button>

            <button
                class="btn btn-warning"
                v-if="playState == PlayState.PLAYING"
                @click="pause"
            >
                Pause Reader
            </button>

            <button
                class="btn btn-danger"
                v-if="playState != PlayState.STOPPED || isOnLastWord"
                @click="end"
            >
                {{ isOnLastWord ? "Restart Reader" : "End Reader" }}
            </button>
        </div>

        <div class="mt-5">
            <p class="text-center fs-6 fw-light">
                {{ wpm }} words per minute
            </p>
            <!-- 
                Main word reader display section.

                This part centers and aligns the current word broken into three segments:
                  - beforeRedLetter: Characters before the "pivot" (middle letter)
                  - redLetter: The "pivot" character, visually emphasized in red for the "Optimal Recognition Point"
                  - afterRedLetter: Characters after the "pivot" letter
                
                The styling ensures the pivot letters of different words always appear in the same horizontal spot, 
                minimizing eye movement and maximizing reading speed. Each <span> uses both Bootstrap classes and specific inline styles:

                    - min-width: Ensures each segment (left, pivot, right) reserves minimum space, so short words don't collapse layout
                    - white-space: pre; Keeps spacing and disables word breaks, so alignment remains stable
                    - margin & padding tweaks: Remove unwanted extra space between or around spans to keep the focus point rock-steady
                    - text alignment: Each span is aligned (left, center, right) to consistently frame the red letter

                The containing <div> centers everything and sets a vertical height for a pleasant visual anchor.
            -->
            <div
                class="d-flex justify-content-center align-items-center"
                style="height: 6em;"
            >
                <!--
                    beforeRedLetter:
                      - text-end: Right-aligns the text for consistent left edge
                      - fs-1 fw-bold: Large, bold font for readability
                      - white-space: pre;   Ensures spaces are preserved, disables wrapping
                      - min-width: 4ch;     Forces this "slot" to be at least 4 characters wide, so the pivot letter is always horizontally aligned (even for short words)
                      - margin-right, padding-right: 0;   Removes any default spacing, so left segment sits flush against the red letter
                -->
                <span
                    class="text-end fs-1 fw-bold"
                    style="white-space: pre; min-width: 4ch; margin-right: 0; padding-right: 0;"
                >{{ beforeRedLetter }}</span>
                
                <!--
                    redLetter:
                      - text-danger: Makes letter red to mark the Optimal Recognition Point for reading
                      - text-center, fs-1, fw-bold: Centered, large, bold visual
                      - min-width: 1ch;   Ensures at least 1 character slot regardless of content (prevents jitter)
                      - margin, padding: 0; Keeps letter tightly spaced to left/right, prevents gaps from growing due to font/DOM quirks
                -->
                <span
                    class="text-danger text-center fs-1 fw-bold"
                    style="min-width: 1ch; margin: 0; padding: 0;"
                >{{ redLetter }}</span>
                
                <!--
                    afterRedLetter:
                      - text-start: Left-aligns text so any trailing characters do not interfere with the pivot
                      - fs-1 fw-bold: Large, bold font for consistency
                      - white-space: pre;   Prevents wrapping, preserves alignment
                      - min-width: 4ch;     Pads the right segment equally to the left, for symmetric "slots"
                      - margin-left, padding-left: 0;   No spacing between this and the red letter, so segments are snug
                -->
                <span
                    class="text-start fs-1 fw-bold"
                    style="white-space: pre; min-width: 4ch; margin-left: 0; padding-left: 0;"
                >{{ afterRedLetter }}</span>
            </div>
  
  
            <!-- Controls to manually move through word list -->
            <div class="row" v-if="playState != PlayState.PLAYING">
                <!-- button to move to previous word -->
                <div class="col d-grid">
                    <button
                        class="btn btn-warning"
                        :disabled="wordIndex == 0"
                        @click="wordIndex--"
                    >Previous</button>
                </div>
                <!-- spacer -->
                <div class="col"></div>
                <!-- button to move to next word -->
                <div class="col d-grid">
                    <button
                        class="btn btn-warning"
                        :disabled="wordIndex == wordList.length - 1"
                        @click="wordIndex++"
                    >Next</button>
                </div>
            </div>

            <!-- progress bar for visual representation of reading progress -->
            <div class="my-5" style="position: relative; height: 30px;">
                <!-- Visual progress bar background -->
                <div class="progress" style="height: 100%;">
                    <div
                        v-if="wordIndex == 0"
                        class="progress-bar progress-bar-striped no-transition"
                        style="width: 0%"
                    ></div>
                    <div
                        v-else
                        class="progress-bar progress-bar-striped no-transition"
                        :class="playState == PlayState.PLAYING ? 'progress-bar-animated' : ''"
                        :style="{ width: `${(wordIndex + 1) / wordList.length * 100}%` }"
                    ></div>
                </div>

                <!-- Draggable slider overlay for seeking -->
                <input
                    type="range"
                    class="form-range"
                    style="
                        position: absolute;
                        top: 0;
                        left: 0;
                        width: 100%;
                        height: 100%;
                        opacity: 0;
                        cursor: pointer;
                        margin: 0;
                        z-index: 2;"
                    min="0"
                    :max="wordList.length - 1"
                    step="1"
                    v-model.number="wordIndex"
                    :disabled="playState == PlayState.PLAYING"
                >
            </div>
        </div>

    </div>
</template>

<style scoped>
.no-transition {
    transition: none !important;
}
</style>
