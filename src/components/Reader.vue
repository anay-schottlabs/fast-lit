<script setup>
import { ref } from 'vue';

// text in the textarea is passed down from App.vue
const props = defineProps({
    text: String
});

// the list that will be used to play text
// starts out empty, will be filled up by the parse method
const wordList = ref([]);

// the index of the current word in the word list
const wordIndex = ref(0);

// enum to manage reader states
const PlayState = Object.freeze({
    STOPPED: "stopped",
    PAUSED: "paused",
    PLAYING: "playing"
});

const didParse = ref(false);

const playState = ref(PlayState.STOPPED);

// time text was last parsed at
const parsedAt = ref("");

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
 * This method is intended to be called when the user clicks "Parse Text".
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

    // Output resulting word list to console for verification/debugging
    console.log(wordList.value);

    // store the time that the text was parsed at
    parsedAt.value = new Date().toLocaleTimeString("en-US", {
        hour: "numeric",
        minute: "2-digit",
        hour12: true
    });

    // if the text is not empty, show the parsed words
    if (wordList.value[0] != "") {
        didParse.value = true;
    }
    // if the text is empty, hide the parsed words
    else {
        didParse.value = false;
    }
}

function start() {
    playState.value = PlayState.PLAYING;
}

function pause() {
    playState.value = PlayState.PAUSED;
}

function end() {
    playState.value = PlayState.STOPPED;
}
</script>

<template>
    <div class="d-flex flex-column">

        <!-- Parse Button Section -->
        <div class="d-grid mb-1">
            <!-- Button to parse the raw text input -->
            <button 
                class="btn btn-secondary" 
                @click="parse"
            >
                Parse Text
            </button>
        </div>

        <!-- Reader Controls Section -->
        <div v-if="didParse" class="btn-group mb-5">
            <!-- Show "Start/Continue Reader" if NOT currently playing -->
            <button
                class="btn btn-primary"
                v-if="playState != PlayState.PLAYING"
                @click="start"
            >
                {{ playState == PlayState.PAUSED ? "Continue Reader" : "Start Reader" }}
            </button>

            <!-- Show "Pause Reader" button ONLY if currently playing -->
            <button
                class="btn btn-warning"
                v-if="playState == PlayState.PLAYING"
                @click="pause"
            >
                Pause Reader
            </button>

            <!-- Show "End Reader" unless already stopped -->
            <button
                class="btn btn-danger"
                v-if="playState != PlayState.STOPPED"
                @click="end"
            >
                End Reader
            </button>
        </div>

        <!-- Display parsed text info and the current word only after parsing -->
        <div v-if="didParse" class="mt-5">
            <!-- Show time at which text was parsed -->
            <p class="text-center fs-6 fw-light">
                Parsed at {{ parsedAt }}
            </p>
            <!-- Show the word currently being displayed by the reader -->
            <p class="text-center fs-1 fw-bold">
                {{ wordList[wordIndex] }}
            </p>
            <!-- Controls to manually move through word list -->
            <div class="row">
                <div class="col d-grid">
                    <button
                        class="btn btn-warning"
                        :disabled="wordIndex == 0"
                        @click="wordIndex--"
                    >Previous</button>
                </div>
                <div class="col"></div>
                <div class="col d-grid">
                    <button
                        class="btn btn-warning"
                        :disabled="wordIndex == wordList.length - 1"
                        @click="wordIndex++"
                    >Next</button>
                </div>
            </div>
        </div>

    </div>
</template>

<style scoped></style>
