<script setup>
import { ref, computed } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, doc, setDoc, addDoc, serverTimestamp } from 'firebase/firestore';
import Header from '../components/Header.vue';
import Reader from '../components/Reader.vue';
import { trials as trialConfig, passages, quizzes } from '@/assets/labData.js';

// enum for the four screens a lab session moves through, in order
const Stage = Object.freeze({
    SETUP: 'setup',
    READING: 'reading',
    QUIZ: 'quiz',
    DONE: 'done'
});

const stage = ref(Stage.SETUP);

// ----- session setup -----

const participantId = ref('');
const isStarting = ref(false);
const startError = ref('');

function generateSessionId() {
    return `session_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

// Generated once up front (not at submit time) so the setup screen can show
// the participant the actual ID that will be recorded before they commit.
const sessionId = ref(generateSessionId());

// Fisher-Yates shuffle — randomizes trial order per participant to control
// for practice/fatigue effects, per the study design.
function shuffle(array) {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
}

// The shuffled trial list actually shown to this participant, each entry
// tagged with the order index it was shown in (trialOrderIndex is what gets
// written to every trial record, not the original config-array position).
const trialOrder = ref([]);
const currentTrialIndex = ref(0);

async function startSession() {
    if (!participantId.value.trim() || isStarting.value) {
        return;
    }
    isStarting.value = true;
    startError.value = '';

    const shuffled = shuffle(trialConfig).map((trial, index) => ({
        ...trial,
        trialOrderIndex: index
    }));

    try {
        await setDoc(doc(db, 'labSessions', sessionId.value), {
            sessionId: sessionId.value,
            participantId: participantId.value.trim(),
            trialOrder: shuffled,
            createdAt: serverTimestamp()
        });

        trialOrder.value = shuffled;
        currentTrialIndex.value = 0;
        stage.value = Stage.READING;
    } catch (err) {
        console.error('Failed to start lab session:', err);
        startError.value = 'Could not start the session — check your connection and try again.';
    } finally {
        isStarting.value = false;
    }
}

// ----- trial sequence -----

const currentTrial = computed(() => trialOrder.value[currentTrialIndex.value]);
const currentPassage = computed(() => passages.find((p) => p.id === currentTrial.value?.passageId));
const currentQuiz = computed(() => quizzes[currentTrial.value?.passageId] ?? []);

// Timestamps for the current trial's reading stage, captured via Reader's
// "started"/"finished" events (see the Reader below). Plain vars, not refs —
// nothing in the template needs to react to these directly.
let trialStartTime = null;
let trialEndTime = null;
let quizStartTime = null;

function onTrialStarted() {
    trialStartTime = Date.now();
}

function onTrialFinished() {
    trialEndTime = Date.now();
    quizAnswers.value = new Array(currentQuiz.value.length).fill(null);
    quizStartTime = Date.now();
    stage.value = Stage.QUIZ;
}

// ----- comprehension quiz -----

// selected option index per question, null until answered
const quizAnswers = ref([]);
const isSubmittingQuiz = ref(false);
const submitError = ref('');

const allAnswered = computed(() => {
    return quizAnswers.value.length === currentQuiz.value.length
        && quizAnswers.value.every((answer) => answer !== null && answer !== undefined);
});

// A naive word-count / wpm estimate. Reader.vue adds extra pause ticks after
// punctuation (periods, commas, etc.), so actualDurationMs is *expected* to
// run somewhat longer than this — that's normal RSVP pacing, not a bug. The
// 30% threshold below is a guess at a gap wide enough to flag something else
// going on (a backgrounded tab throttling timers, a stalled participant,
// etc.) without flagging every trial purely for having punctuation pauses.
const DURATION_MISMATCH_THRESHOLD = 0.3;

async function submitQuiz() {
    if (!allAnswered.value || isSubmittingQuiz.value) {
        return;
    }
    isSubmittingQuiz.value = true;
    submitError.value = '';

    const quizDurationMs = Date.now() - quizStartTime;
    const actualDurationMs = trialEndTime - trialStartTime;
    const wordCount = currentPassage.value.text.trim().split(/\s+/).length;
    const expectedDurationMs = Math.round((wordCount / currentTrial.value.wpm) * 60000);
    const durationMismatchFlag =
        Math.abs(actualDurationMs - expectedDurationMs) / expectedDurationMs > DURATION_MISMATCH_THRESHOLD;

    const correctCount = quizAnswers.value.reduce((count, answer, i) => {
        return count + (answer === currentQuiz.value[i].correctIndex ? 1 : 0);
    }, 0);

    const trialRecord = {
        sessionId: sessionId.value,
        participantId: participantId.value.trim(),
        passageId: currentTrial.value.passageId,
        wpm: currentTrial.value.wpm,
        trialOrderIndex: currentTrial.value.trialOrderIndex,
        actualStartTime: trialStartTime,
        actualEndTime: trialEndTime,
        actualDurationMs,
        expectedDurationMs,
        durationMismatchFlag,
        quizAnswers: [...quizAnswers.value],
        correctCount,
        totalQuestions: currentQuiz.value.length,
        quizDurationMs,
        timestamp: serverTimestamp()
    };

    try {
        await addDoc(collection(db, 'labTrials'), trialRecord);
    } catch (err) {
        console.error('Failed to save trial record:', err);
        submitError.value = 'Could not save this trial — check your connection and try again.';
        isSubmittingQuiz.value = false;
        return;
    }

    isSubmittingQuiz.value = false;

    if (currentTrialIndex.value < trialOrder.value.length - 1) {
        currentTrialIndex.value++;
        stage.value = Stage.READING;
    } else {
        stage.value = Stage.DONE;
    }
}
</script>

<template>
    <!-- session setup screen -->
    <div v-if="stage === Stage.SETUP" class="mx-auto max-w-xl p-5">
        <Header pageName="Lab" />

        <div class="mt-10 rounded-3xl border border-white/10 bg-white/5 p-8 shadow-2xl shadow-black/40">
            <h2 class="mb-2 text-2xl font-bold">New Session</h2>
            <p class="mb-6 text-sm text-white/60">
                Enter a participant name or ID to begin. A session ID is generated automatically below.
            </p>

            <label class="mb-2 block text-xs font-semibold uppercase tracking-widest text-white/50">
                Participant Name / ID
            </label>
            <input
                v-model="participantId"
                type="text"
                class="input w-full mb-5 rounded-2xl border border-white/10 bg-white/5 focus-ring"
                placeholder="e.g. P07"
                @keyup.enter="startSession"
            />

            <p class="mb-6 text-xs text-white/40">
                Session ID: <span class="font-mono text-white/60">{{ sessionId }}</span>
            </p>

            <p v-if="startError" class="mb-4 text-center text-sm text-red-light">{{ startError }}</p>

            <button
                class="btn-red w-full"
                :disabled="!participantId.trim() || isStarting"
                @click="startSession"
            >
                {{ isStarting ? 'Starting…' : 'Start Session' }}
            </button>
        </div>
    </div>

    <!-- reading stage: reuses Reader.vue, locked down so a trial can only be
         played through once started, and isolated from the main /read page's
         localStorage progress and the site's aggregate word-count stats -->
    <div v-else-if="stage === Stage.READING" class="mx-auto max-w-4xl p-5">
        <Header pageName="Lab" />

        <p class="mb-4 mt-2 text-center text-xs font-semibold uppercase tracking-widest text-white/50">
            Trial {{ currentTrialIndex + 1 }} of {{ trialOrder.length }}
        </p>

        <Reader
            v-if="currentPassage"
            :key="currentTrial.passageId + '-' + currentTrialIndex"
            :text="currentPassage.text"
            :wpm="currentTrial.wpm"
            :settings-modal="false"
            :min-wpm="60"
            :max-wpm="600"
            :wpm-step="20"
            :persist-progress="false"
            :track-stats="false"
            :lock-controls="true"
            @started="onTrialStarted"
            @finished="onTrialFinished"
        />
    </div>

    <!-- comprehension quiz, shown immediately after a trial's passage finishes -->
    <div v-else-if="stage === Stage.QUIZ" class="mx-auto max-w-2xl p-5">
        <Header pageName="Lab" />

        <p class="mb-6 mt-2 text-center text-xs font-semibold uppercase tracking-widest text-white/50">
            Trial {{ currentTrialIndex + 1 }} of {{ trialOrder.length }} — Comprehension Check
        </p>

        <div
            v-for="(question, qi) in currentQuiz"
            :key="qi"
            class="mb-6 rounded-2xl border border-white/10 bg-white/5 p-5 shadow-2xl shadow-black/40"
        >
            <p class="mb-3 font-semibold">{{ qi + 1 }}. {{ question.question }}</p>
            <div class="flex flex-col gap-2">
                <label
                    v-for="(option, oi) in question.options"
                    :key="oi"
                    class="flex cursor-pointer items-center gap-3 rounded-xl border border-white/10 px-4 py-2 transition-colors hover:bg-white/10"
                    :class="{ '!border-red bg-red/10': quizAnswers[qi] === oi }"
                >
                    <input
                        type="radio"
                        class="radio"
                        :name="'trial-question-' + qi"
                        :value="oi"
                        v-model="quizAnswers[qi]"
                    />
                    <span>{{ option }}</span>
                </label>
            </div>
        </div>

        <p v-if="submitError" class="mb-4 text-center text-sm text-red-light">{{ submitError }}</p>

        <button
            class="btn-red w-full"
            :disabled="!allAnswered || isSubmittingQuiz"
            @click="submitQuiz"
        >
            {{ isSubmittingQuiz ? 'Saving…' : (currentTrialIndex < trialOrder.length - 1 ? 'Next Trial' : 'Finish') }}
        </button>
    </div>

    <!-- end screen — deliberately shows no results, so a participant running
         multiple sessions (however unlikely) isn't biased by their own past performance -->
    <div v-else-if="stage === Stage.DONE" class="mx-auto max-w-xl p-5 text-center">
        <Header pageName="Lab" />

        <div class="mt-16 rounded-3xl border border-white/10 bg-white/5 p-10 shadow-2xl shadow-black/40">
            <h2 class="mb-3 text-3xl font-bold !text-red">Thanks, you're done!</h2>
            <p class="text-white/70">Your responses have been recorded. You can close this window now.</p>
        </div>
    </div>
</template>

<style scoped></style>
