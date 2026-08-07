<script setup>
import { ref, computed } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import Reader from '../components/Reader.vue';
import { trials as trialConfig, passages, quizzes } from '@/assets/labData.js';

// enum for the screens a run moves through, in order (SAVING sits between
// the last trial's last question and DONE, since the Firestore write can
// fail and need a retry before DONE is reachable)
const Stage = Object.freeze({
    START: 'start',
    READING: 'reading',
    QUIZ: 'quiz',
    SAVING: 'saving',
    DONE: 'done'
});

const stage = ref(Stage.START);

// Fisher-Yates shuffle — randomizes trial order per run to control for
// practice/fatigue effects; the position actually shown is still recorded
// per trial below.
function shuffle(array) {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
}

const trialOrder = ref([]);
const currentTrialIndex = ref(0);

// Finished trial records accumulate here as the run progresses, then get
// bundled into one Firestore write at the very end (see finalizeRun) —
// there's no participant/session identity to key separate writes on, so a
// single per-run document is simpler and keeps a run's data together.
const completedTrials = ref([]);

let runStartTime = null;

function beginRun() {
    trialOrder.value = shuffle(trialConfig).map((trial, index) => ({
        ...trial,
        position: index
    }));
    currentTrialIndex.value = 0;
    completedTrials.value = [];
    runStartTime = Date.now();
    stage.value = Stage.READING;
}

const currentTrial = computed(() => trialOrder.value[currentTrialIndex.value]);
const currentPassage = computed(() => passages.find((p) => p.id === currentTrial.value?.passageId));
const currentQuizQuestions = computed(() => quizzes[currentTrial.value?.passageId] ?? []);

// Timestamps for the current trial's reading stage, captured via Reader's
// "started"/"finished" events. Plain vars, not refs — nothing in the
// template reacts to these directly.
let trialStartTime = null;
let trialEndTime = null;

function onTrialStarted() {
    trialStartTime = Date.now();
}

function onTrialFinished() {
    trialEndTime = Date.now();
    currentQuestionIndex.value = 0;
    selectedOption.value = null;
    questionAnswers.value = [];
    questionShownAt = Date.now();
    stage.value = Stage.QUIZ;
}

// ----- one-question-at-a-time comprehension quiz -----

const currentQuestionIndex = ref(0);
const selectedOption = ref(null);
const questionAnswers = ref([]);
let questionShownAt = null;

const currentQuestion = computed(() => currentQuizQuestions.value[currentQuestionIndex.value]);
const isLastQuestionOfTrial = computed(() => currentQuestionIndex.value === currentQuizQuestions.value.length - 1);
const isFinalQuestionOfRun = computed(() => isLastQuestionOfTrial.value && currentTrialIndex.value === trialOrder.value.length - 1);

function submitQuestion() {
    if (selectedOption.value === null) {
        return;
    }

    // Time-to-answer for exactly this question, per the paper's own
    // "time per question" requirement — not just a whole-quiz total.
    const timeMs = Date.now() - questionShownAt;
    questionAnswers.value.push({
        question: currentQuestion.value.question,
        options: currentQuestion.value.options,
        correctIndex: currentQuestion.value.correctIndex,
        selectedIndex: selectedOption.value,
        selectedOption: currentQuestion.value.options[selectedOption.value],
        isCorrect: selectedOption.value === currentQuestion.value.correctIndex,
        timeMs
    });

    if (isLastQuestionOfTrial.value) {
        finishTrialQuiz();
    } else {
        currentQuestionIndex.value++;
        selectedOption.value = null;
        questionShownAt = Date.now();
    }
}

// A naive word-count / wpm estimate. Reader.vue adds extra pause ticks after
// punctuation, so actualDurationMs is *expected* to run a bit longer than
// this — normal RSVP pacing, not a bug. 30% is a guess at a gap wide enough
// to flag something else going on (a backgrounded tab throttling timers, a
// stalled reader) without flagging every trial purely for punctuation pauses.
const DURATION_MISMATCH_THRESHOLD = 0.3;

function finishTrialQuiz() {
    const wordCount = currentPassage.value.text.trim().split(/\s+/).length;
    const actualDurationMs = trialEndTime - trialStartTime;
    const expectedDurationMs = Math.round((wordCount / currentTrial.value.wpm) * 60000);
    const durationMismatchFlag =
        Math.abs(actualDurationMs - expectedDurationMs) / expectedDurationMs > DURATION_MISMATCH_THRESHOLD;
    // The reading speed the participant actually achieved, vs. the trial's
    // configured/nominal wpm — useful on its own as an analysis variable.
    const achievedWpm = Math.round(wordCount / (actualDurationMs / 60000));

    const correctCount = questionAnswers.value.filter((a) => a.isCorrect).length;
    const totalQuestions = questionAnswers.value.length;
    const quizDurationMs = questionAnswers.value.reduce((sum, a) => sum + a.timeMs, 0);

    completedTrials.value.push({
        position: currentTrial.value.position,
        passageId: currentTrial.value.passageId,
        wpm: currentTrial.value.wpm,
        wordCount,
        actualStartTime: trialStartTime,
        actualEndTime: trialEndTime,
        actualDurationMs,
        expectedDurationMs,
        durationMismatchFlag,
        achievedWpm,
        quiz: {
            totalQuestions,
            correctCount,
            accuracyPct: totalQuestions ? (correctCount / totalQuestions) * 100 : 0,
            quizDurationMs,
            questions: [...questionAnswers.value]
        }
    });

    if (currentTrialIndex.value < trialOrder.value.length - 1) {
        currentTrialIndex.value++;
        stage.value = Stage.READING;
    } else {
        stage.value = Stage.SAVING;
        finalizeRun();
    }
}

// ----- save the whole run as one Firestore document -----

const isSaving = ref(false);
const saveError = ref('');

async function finalizeRun() {
    isSaving.value = true;
    saveError.value = '';
    const runEndTime = Date.now();

    const totalReadingMs = completedTrials.value.reduce((sum, t) => sum + t.actualDurationMs, 0);
    const totalQuizMs = completedTrials.value.reduce((sum, t) => sum + t.quiz.quizDurationMs, 0);
    const totalCorrect = completedTrials.value.reduce((sum, t) => sum + t.quiz.correctCount, 0);
    const totalQuestions = completedTrials.value.reduce((sum, t) => sum + t.quiz.totalQuestions, 0);

    const runRecord = {
        trials: completedTrials.value,
        runStartedAt: runStartTime,
        runEndedAt: runEndTime,
        totalElapsedMs: runEndTime - runStartTime,
        totalReadingMs,
        totalQuizMs,
        overallAccuracyPct: totalQuestions ? (totalCorrect / totalQuestions) * 100 : 0,
        // Lightweight, non-identifying environment context — useful for a
        // paper (e.g. filtering out mobile vs. desktop) without asking the
        // participant anything.
        userAgent: navigator.userAgent,
        createdAt: serverTimestamp()
    };

    try {
        await addDoc(collection(db, 'labRuns'), runRecord);
        stage.value = Stage.DONE;
    } catch (err) {
        console.error('Failed to save lab run:', err);
        saveError.value = 'Could not save your results — check your connection and try again.';
    } finally {
        isSaving.value = false;
    }
}
</script>

<template>
    <!-- start screen — no participant/session fields, just an explanation and a Begin button -->
    <div v-if="stage === Stage.START" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <h2 class="mb-3 text-2xl font-bold !text-ink">Reading Study</h2>
            <p class="mb-8 !text-ink-light">
                You'll read three short passages at different speeds. After each one, answer a few quick
                comprehension questions. It takes about five minutes.
            </p>
            <button class="btn-primary w-full" @click="beginRun">Begin</button>
        </div>
    </div>

    <!-- reading stage: reuses Reader.vue, locked down so a trial can only be
         played through once started, and isolated from the main /read page's
         localStorage progress and the site's aggregate word-count stats -->
    <div v-else-if="stage === Stage.READING" class="mx-auto max-w-4xl px-5 pt-16 pb-5">
        <p class="mb-4 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Passage {{ currentTrialIndex + 1 }} of {{ trialOrder.length }}
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

    <!-- comprehension quiz — one question at a time, so time-to-answer can
         be measured per question rather than only for the quiz as a whole -->
    <div v-else-if="stage === Stage.QUIZ" class="mx-auto max-w-2xl px-5 pt-16 pb-5">
        <p class="mb-2 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Passage {{ currentTrialIndex + 1 }} of {{ trialOrder.length }} — Question
            {{ currentQuestionIndex + 1 }} of {{ currentQuizQuestions.length }}
        </p>

        <div class="mt-6 rounded-2xl border border-border bg-card p-6">
            <p class="mb-5 text-lg font-semibold !text-ink">{{ currentQuestion.question }}</p>
            <div class="flex flex-col gap-2">
                <label
                    v-for="(option, oi) in currentQuestion.options"
                    :key="oi"
                    class="flex cursor-pointer items-center gap-3 rounded-xl border px-4 py-3 transition-colors hover:bg-ink/5"
                    :class="selectedOption === oi ? 'border-ink bg-ink/10' : 'border-border'"
                >
                    <input type="radio" class="radio accent-ink" name="quiz-option" :value="oi" v-model="selectedOption" />
                    <span class="!text-ink">{{ option }}</span>
                </label>
            </div>
        </div>

        <button
            class="btn-primary w-full mt-6"
            :disabled="selectedOption === null"
            @click="submitQuestion"
        >
            {{ isFinalQuestionOfRun ? 'Finish' : 'Next' }}
        </button>
    </div>

    <!-- saving the run — a distinct screen (not folded into DONE) so a
         failed write shows a retry instead of silently losing the data -->
    <div v-else-if="stage === Stage.SAVING" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <p v-if="isSaving" class="!text-ink-light">Saving your results…</p>
            <template v-else>
                <p class="mb-4 text-error">{{ saveError }}</p>
                <button class="btn-primary w-full" @click="finalizeRun">Try Again</button>
            </template>
        </div>
    </div>

    <!-- end screen — no results shown -->
    <div v-else-if="stage === Stage.DONE" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <h2 class="mb-3 text-3xl font-bold !text-ink">Thanks, you're done!</h2>
            <p class="!text-ink-light">Your responses have been recorded. You can close this window now.</p>
        </div>
    </div>

</template>

<style scoped></style>
