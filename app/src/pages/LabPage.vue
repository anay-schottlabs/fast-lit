<script setup>
import { ref, computed, onUnmounted } from 'vue';
import Reader from '../components/Reader.vue';
import { passages } from '@/assets/labData.js';

// Every screen the run can be on, in roughly the order a participant moves
// through them. RSVP/TIMED/QUIZ repeat three times (once per main-trial
// speed) before landing on DONE.
const Stage = Object.freeze({
    START: 'start',
    PRACTICE: 'practice',
    PRACTICE_DONE: 'practice_done',
    RSVP: 'rsvp',
    TIMED: 'timed',
    QUIZ: 'quiz',
    DONE: 'done'
});

const stage = ref(Stage.START);

// Fisher-Yates shuffle — used to randomly assign passages to trials without
// repeats (see buildMainTrials below).
function shuffle(array) {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
}

// ----- practice trial: always first, always 100 wpm, fixed text, no quiz -----

const PRACTICE_WPM = 100;
const PRACTICE_TEXT =
    "This experiment tests how well people understand text shown using a technique called RSVP, or rapid serial visual presentation. Instead of reading a full page, words appear one at a time, right here on the screen, at a fixed pace you don't control. Today, you'll read several short passages this way, at three different speeds, and after each one you'll answer a few comprehension questions. You'll also read some passages normally, but with a time limit. Just read naturally and answer as best you can. This practice round is running at a slower pace, so you can get a feel for how the words will appear before the real trials begin.";

function beginPractice() {
    stage.value = Stage.PRACTICE;
}

function onPracticeFinished() {
    stage.value = Stage.PRACTICE_DONE;
}

// ----- main trials: fixed ascending speed order, RSVP then timed at each -----

const MAIN_SPEEDS = [250, 350, 450];

// One passage per trial (RSVP + timed, at each of the three speeds), drawn
// without replacement so no passage repeats within a run.
function buildMainTrials(pool) {
    const drawn = shuffle(pool).slice(0, MAIN_SPEEDS.length * 2);
    let cursor = 0;
    const trials = [];
    for (const wpm of MAIN_SPEEDS) {
        trials.push({ mode: 'rsvp', wpm, passage: drawn[cursor++] });
        trials.push({ mode: 'timed', wpm, passage: drawn[cursor++] });
    }
    return trials;
}

const trials = ref([]);
const currentTrialIndex = ref(0);
const currentTrial = computed(() => trials.value[currentTrialIndex.value]);

function beginMainTrials() {
    trials.value = buildMainTrials(passages);
    currentTrialIndex.value = 0;
    enterCurrentTrial();
}

function enterCurrentTrial() {
    const trial = currentTrial.value;
    if (trial.mode === 'rsvp') {
        stage.value = Stage.RSVP;
    } else {
        stage.value = Stage.TIMED;
        startTimedCountdown(trial);
    }
}

function goToQuiz() {
    currentQuestionIndex.value = 0;
    selectedOption.value = null;
    stage.value = Stage.QUIZ;
}

function onRsvpTrialFinished() {
    goToQuiz();
}

// ----- timed (non-RSVP) reading trial: static text + countdown -----

const timedSecondsRemaining = ref(0);
let timedIntervalId = null;

function startTimedCountdown(trial) {
    const wordCount = trial.passage.text.trim().split(/\s+/).length;
    const totalSeconds = Math.max(1, Math.round((wordCount / trial.wpm) * 60));
    timedSecondsRemaining.value = totalSeconds;

    clearInterval(timedIntervalId);
    timedIntervalId = setInterval(() => {
        timedSecondsRemaining.value--;
        if (timedSecondsRemaining.value <= 0) {
            finishTimedTrial();
        }
    }, 1000);
}

function finishTimedTrial() {
    clearInterval(timedIntervalId);
    timedIntervalId = null;
    goToQuiz();
}

onUnmounted(() => clearInterval(timedIntervalId));

const timedTimeDisplay = computed(() => {
    const seconds = Math.max(0, timedSecondsRemaining.value);
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes}:${String(secs).padStart(2, '0')}`;
});

// ----- one-question-at-a-time comprehension quiz (shared by rsvp + timed) -----

const currentQuestionIndex = ref(0);
const selectedOption = ref(null);

const currentQuizQuestions = computed(() => currentTrial.value?.passage.questions ?? []);
const currentQuestion = computed(() => currentQuizQuestions.value[currentQuestionIndex.value]);
const isLastQuestionOfTrial = computed(() => currentQuestionIndex.value === currentQuizQuestions.value.length - 1);
const isFinalQuestionOfRun = computed(() => isLastQuestionOfTrial.value && currentTrialIndex.value === trials.value.length - 1);

function submitQuestion() {
    if (selectedOption.value === null) {
        return;
    }

    if (isLastQuestionOfTrial.value) {
        advanceToNextTrialOrFinish();
    } else {
        currentQuestionIndex.value++;
        selectedOption.value = null;
    }
}

function advanceToNextTrialOrFinish() {
    if (currentTrialIndex.value < trials.value.length - 1) {
        currentTrialIndex.value++;
        enterCurrentTrial();
    } else {
        stage.value = Stage.DONE;
    }
}
</script>

<template>
    <!-- start screen -->
    <div v-if="stage === Stage.START" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <h2 class="mb-3 text-2xl font-bold !text-ink">Reading Study</h2>
            <p class="mb-8 !text-ink-light">
                You'll start with a short practice round, then read six short passages — some using
                word-at-a-time display, some normally with a time limit — answering a few comprehension
                questions after each one.
            </p>
            <button class="btn-primary w-full" @click="beginPractice">Begin</button>
        </div>
    </div>

    <!-- practice trial: fixed text, 100 wpm, no quiz afterward -->
    <div v-else-if="stage === Stage.PRACTICE" class="mx-auto max-w-4xl px-5 pt-16 pb-5">
        <p class="mb-4 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Practice Round
        </p>
        <Reader
            :text="PRACTICE_TEXT"
            :wpm="PRACTICE_WPM"
            :settings-modal="false"
            :min-wpm="60"
            :max-wpm="600"
            :wpm-step="20"
            :persist-progress="false"
            :track-stats="false"
            :lock-controls="true"
            @finished="onPracticeFinished"
        />
    </div>

    <!-- practice confirmation screen -->
    <div v-else-if="stage === Stage.PRACTICE_DONE" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <h2 class="mb-3 text-2xl font-bold !text-ink">Ready to begin the real trials?</h2>
            <p class="mb-8 !text-ink-light">
                Take a moment if you need it. The real trials work the same way, just at different speeds.
            </p>
            <button class="btn-primary w-full" @click="beginMainTrials">Continue</button>
        </div>
    </div>

    <!-- rsvp main trial -->
    <div v-else-if="stage === Stage.RSVP" class="mx-auto max-w-4xl px-5 pt-16 pb-5">
        <p class="mb-4 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Trial {{ currentTrialIndex + 1 }} of {{ trials.length }}
        </p>
        <Reader
            v-if="currentTrial"
            :key="currentTrial.passage.id + '-' + currentTrialIndex"
            :text="currentTrial.passage.text"
            :wpm="currentTrial.wpm"
            :settings-modal="false"
            :min-wpm="60"
            :max-wpm="600"
            :wpm-step="20"
            :persist-progress="false"
            :track-stats="false"
            :lock-controls="true"
            @finished="onRsvpTrialFinished"
        />
    </div>

    <!-- timed, normal-reading main trial -->
    <div v-else-if="stage === Stage.TIMED" class="mx-auto max-w-2xl px-5 pt-16 pb-5">
        <p class="mb-2 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Trial {{ currentTrialIndex + 1 }} of {{ trials.length }}
        </p>
        <p class="mb-6 text-center text-3xl font-bold !text-ink">{{ timedTimeDisplay }}</p>

        <div class="rounded-2xl border border-border bg-card p-6 !text-ink whitespace-pre-line leading-relaxed">
            {{ currentTrial.passage.text }}
        </div>

        <button class="btn-primary w-full mt-6" @click="finishTimedTrial">Done</button>
    </div>

    <!-- comprehension quiz — shared by rsvp and timed trials -->
    <div v-else-if="stage === Stage.QUIZ" class="mx-auto max-w-2xl px-5 pt-16 pb-5">
        <p class="mb-2 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Trial {{ currentTrialIndex + 1 }} of {{ trials.length }} — Question
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

    <!-- end screen -->
    <div v-else-if="stage === Stage.DONE" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <h2 class="mb-3 text-3xl font-bold !text-ink">Thanks, you're done!</h2>
        </div>
    </div>
</template>

<style scoped></style>
