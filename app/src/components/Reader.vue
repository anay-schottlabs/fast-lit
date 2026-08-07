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

// Persists how far into the text the user has read, so reloading the page
// resumes at the same word instead of starting over. Same try/catch pattern
// as the text/wpm persistence in ReadPage.vue — degrades to in-session-only
// if localStorage is unavailable.
const READ_PROGRESS_STORAGE_KEY = "fastlit:readProgress";

// Guards saveWordIndex from persisting anything before parse() has actually
// restored the saved index (see parse() below). Without this, any wordIndex
// write that happens before that restore — e.g. wordIndex's own ref(0)
// initialization being observed, or v-model syncing against the range
// input's default max before wordList is populated — would overwrite the
// saved progress with 0 before it's ever read back, which is exactly the
// bug reported: localStorage showed 0 before restoration got a chance to run.
let hasRestoredProgress = false;

function loadSavedWordIndex() {
    if (!props.persistProgress) {
        return 0;
    }
    try {
        return Number(localStorage.getItem(READ_PROGRESS_STORAGE_KEY));
    } catch {
        return 0;
    }
}

function saveWordIndex(value) {
    if (!hasRestoredProgress || !props.persistProgress) {
        return;
    }
    try {
        localStorage.setItem(READ_PROGRESS_STORAGE_KEY, String(value));
    } catch {
        // localStorage unavailable (e.g. private browsing) — reading still
        // works for this session, it just won't persist across reloads.
    }
}

watch(wordIndex, saveWordIndex);

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
    // docId is only set once the Firestore stats doc has loaded (onMounted
    // below); guard against it still being undefined (e.g. a slow/failed
    // fetch), which would otherwise throw trying to build a doc reference.
    if (wordsInSession > 0 && docId) {
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

// get stats from firestore — skipped entirely when trackStats is false (the
// Lab page's research trials), since there's no reason to read the global
// stats doc if we're never going to write to it.
onMounted(async () => {
    if (!props.trackStats) {
        return;
    }
    const querySnapshot = await getDocs(collection(db, "stats"));
    querySnapshot.forEach((doc) => {
        docId = doc.id;
        totalWordsRead.value = doc.data().totalWordsRead;
    });
});

const route = useRoute();

// values passed down from ReadPage.vue (or LabPage.vue, for research trials)
const props = defineProps({
    text: String,
    wpm: Number,
    settingsModal: Boolean,
    minWpm: Number,
    maxWpm: Number,
    wpmStep: Number,
    // Whether to persist/restore reading progress via localStorage. ReadPage
    // relies on this to resume where a user left off; LabPage sets this to
    // false so research trials always start at word 0 and never clobber the
    // user's own in-progress reading on /read (they share one storage key).
    persistProgress: {
        type: Boolean,
        default: true
    },
    // Whether to fetch/update the global Firestore "stats" doc on read
    // completion. LabPage sets this to false — pilot-study reading isn't
    // real app usage and shouldn't count toward the site's aggregate stats.
    trackStats: {
        type: Boolean,
        default: true
    },
    // Hides pause/prev/next/scrub/end controls so a trial can only be played
    // through start-to-finish once started, never paused or rewound. Used by
    // LabPage so a trial's recorded elapsed time actually reflects continuous
    // reading, not something a participant paused partway through.
    lockControls: {
        type: Boolean,
        default: false
    }
});

// events sent by Reader.vue to its parent (ReadPage.vue or LabPage.vue)
const emit = defineEmits([
    "setWpm",
    // Fired the moment playback starts (start() is called).
    "started",
    // Fired only when playback runs to the natural end of the word list —
    // not when the user manually hits the end/reset button.
    "finished"
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

// parse() on empty/whitespace-only text produces wordList = [""], so the
// reading stage would otherwise render completely blank with no explanation.
const hasContent = computed(() => word.value.length > 0);

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

    // Resume saved progress only on the very first parse (component mount,
    // loading the persisted text) — a later text change (the user pasting
    // something new) should still start at the beginning, not some stale
    // index left over from different text.
    if (!hasRestoredProgress) {
        hasRestoredProgress = true;
        const saved = loadSavedWordIndex();
        wordIndex.value = (saved > 0 && saved < wordList.value.length) ? saved : 0;
    }
    else {
        wordIndex.value = 0;
    }
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

// Shared by both "ran out of words" branches in tick() below, so natural
// completion is only defined in one place and always emits "finished".
function finishPlayback() {
    clearInterval(readerLoop);
    playState.value = PlayState.STOPPED;
    emit("finished");
}

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
            finishPlayback();
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
            finishPlayback();
            return;
        }
        wordIndex.value++;
    }
}

function start() {
    playState.value = PlayState.PLAYING;
    readerLoop = setInterval(tick, interval.value);
    emit("started");
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
    if (props.trackStats) {
        updateTotalWordsRead();
    }
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
        // Excludes Ctrl/Cmd+R: that's the browser's reload shortcut, and since
        // event.key is still "r" when held with a modifier, this shortcut was
        // firing end() (resetting progress to 0) a moment before the actual
        // reload — which then persisted the just-reset value, making it look
        // like reading progress never survived a reload at all.
        else if (event.key == "r" && !event.ctrlKey && !event.metaKey) {
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
    <p class="mt-5 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
        Speed
    </p>
    <p class="mb-2 text-center">
        <span class="font-display text-3xl font-bold text-ink">{{ wpm }}</span>
        <span class="text-sm text-ink-light"> words per minute</span>
    </p>

    <!--
        Main word reader display, framed as a distinct "reading stage". Kept
        fully monochrome (ink/ink-light only, no terracotta) to match the
        iOS app's own read screen, which deliberately drops its one accent
        color here — see ContentView.swift's wordDisplay: "in this app's
        monochrome palette there's no separate hue to lean on... the
        focal letter stand[s] out through color contrast alone" (full
        ink center word against muted ink-light before/after text, no
        fixation ticks).
    -->
    <div class="relative my-8 rounded-3xl border border-border bg-card px-6 py-16">
        <template v-if="hasContent">
            <div class="text-5xl font-bold text-center flex sm:text-6xl lg:text-7xl">
                <!-- Shows the part of the word before the highlighted letter, right-aligned within its flex space -->
                <span class="flex-1 text-right text-ink-light">
                    {{ beforeRedLetter }}
                </span>
                <!-- Displays the single focal letter — full-strength ink, same weight as before/after, standing out through lightness contrast rather than a separate accent color -->
                <span class="text-ink">
                    {{ redLetter }}
                </span>
                <!-- Shows the part of the word after the highlighted letter, left-aligned within its flex space -->
                <span class="flex-1 text-left text-ink-light">
                    {{ afterRedLetter }}
                </span>
            </div>
        </template>
        <!-- empty-text state: parse() on blank input still produces one empty
             "word", which would otherwise render this stage completely blank -->
        <p v-else class="text-center text-lg !text-ink-light">
            Add some text in Settings to get started.
        </p>
    </div>

    <!-- progress bar for visual representation of reading progress — hidden
         under lockControls so a research trial can't be scrubbed forward or
         back, which would invalidate the recorded elapsed time. -->
    <input
        v-if="!lockControls"
        type="range"
        min="0"
        :max="wordList.length - 1"
        v-model="wordIndex"
        class="range w-full mb-10 focus-ring"
        :disabled="playState == PlayState.PLAYING"
        :style="playState == PlayState.PLAYING ? 'opacity: 1; pointer-events: none;' : ''"
    />

    <!-- reader controls section -->
    <div class="flex gap-5 justify-center items-center" :class="{ 'mt-10': lockControls }">
        <!-- button to move to previous word — hidden under lockControls.
             A subtle ink-tinted tile (matching the iOS app's own
             "inactiveTileBackground" treatment for its Back/Forward
             buttons), not a filled accent button — this whole reading
             stage stays accent-free. -->
        <button
            v-if="!lockControls"
            class="btn btn-square !text-ink bg-ink/5 rounded-2xl w-14 h-14 shrink-0 transition-all duration-200 opacity-100 hover:bg-ink/10 hover:-translate-y-0.5 disabled:opacity-50 disabled:hover:translate-y-0 focus-ring"
            :disabled="wordIndex == 0 || playState == PlayState.PLAYING"
            @click="wordIndex--"
            id="previousButton"
        >
            <svg
                viewBox="0 0 64 64"
                width="2.5rem"
                height="2.5rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
            >
                <!-- Larger, thicker left arrow (flip of original) -->
                <polyline
                    points="34,18 20,32 34,46"
                    fill="none"
                    stroke="#3D3226"
                    stroke-width="10"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                />
            </svg>
        </button>

        <!-- play button — filled with plain ink (not the terracotta accent
             used everywhere else on the site), matching the iOS app's own
             read screen, which stays fully monochrome. -->
        <button
            class="bg-ink rounded-2xl !h-14 !w-14 !px-0 shrink-0 transition-transform duration-200 hover:-translate-y-0.5 hover:opacity-85 focus-ring"
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
                class="mx-auto fill-invert"
            >
                <path
                    d="M10,8
                       Q8,8 8,10
                       L8,38
                       Q8,40 10,40
                       L38,24
                       Q40,23 38,22
                       Z"
                />
            </svg>
        </button>

        <!-- pause button — hidden under lockControls, so a started trial can
             only run to completion -->
        <button
            class="bg-ink rounded-2xl !h-14 !w-14 !px-0 shrink-0 transition-transform duration-200 hover:-translate-y-0.5 hover:opacity-85 focus-ring"
            @click="pause"
            id="pauseButton"
            v-if="playState == PlayState.PLAYING && !lockControls"
        >
            <svg
                viewBox="0 0 8 8"
                width="2rem"
                height="2rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
                class="mx-auto fill-invert"
            >
                <g>
                    <!-- Give each bar a rounded radius of 0.5 to match visual style of stop button (proportional: stop uses rx=8 for 48x48 box, so rx=0.5 for 2x6 bar) -->
                    <rect x="1" y="1" width="2" height="6" rx="0.5" />
                    <rect x="5" y="1" width="2" height="6" rx="0.5" />
                </g>
            </svg>
        </button>

        <!-- stop/reset button (referred to as "end button") — hidden under
             lockControls, so a trial can't be aborted/reset mid-playback -->
        <button
            v-if="!lockControls"
            class="bg-ink rounded-2xl !h-14 !w-14 !px-0 shrink-0 transition-transform duration-200 hover:-translate-y-0.5 hover:opacity-85 focus-ring"
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
                class="mx-auto fill-invert"
            >
                <!-- Rounded square with same r as play (roughly 8 for 2rem box) -->
                <rect
                    x="8"
                    y="8"
                    width="48"
                    height="48"
                    rx="8"
                />
            </svg>
        </button>

        <!-- button to move to next word — hidden under lockControls -->
        <button
            v-if="!lockControls"
            class="btn btn-square !text-ink bg-ink/5 rounded-2xl w-14 h-14 shrink-0 transition-all duration-200 hover:bg-ink/10 hover:-translate-y-0.5 disabled:opacity-50 disabled:hover:translate-y-0 focus-ring"
            :disabled="wordIndex == wordList.length - 1 || playState == PlayState.PLAYING"
            @click="wordIndex++"
            id="nextButton"
        >
            <svg
                viewBox="0 0 64 64"
                width="2.5rem"
                height="2.5rem"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
                focusable="false"
            >
                <!-- Larger, thicker right arrow -->
                <polyline
                    points="30,18 44,32 30,46"
                    fill="none"
                    stroke="#3D3226"
                    stroke-width="10"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                />
            </svg>
        </button>
    </div>
</template>

<style scoped>
/* Overrides style.css's global .range accent-color (terracotta) — this
   whole reading stage deliberately stays accent-free, matching the iOS
   app's own monochrome read screen. */
.range {
    accent-color: var(--color-ink);
}
</style>
