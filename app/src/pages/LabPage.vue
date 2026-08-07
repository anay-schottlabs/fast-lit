<script setup>
import { ref, computed, onUnmounted } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import Reader from '../components/Reader.vue';
import { passages } from '@/assets/labData.js';

// Every screen the run can be on, in roughly the order a participant moves
// through them. The practice stages walk through regular reading, then the
// quiz UI, then RSVP, one at a time, before the real trials start. Each of
// the six main trials is preceded by its own TRIAL_INTRO explaining that
// specific trial (mode, wpm or time limit) before TIMED/RSVP/QUIZ run, so a
// participant always knows what's coming next rather than being dropped
// into it. SAVING sits between the last quiz and DONE since the Firestore
// write can fail and need a retry before DONE is reachable.
const Stage = Object.freeze({
    START: 'start',
    PRACTICE_REGULAR: 'practice_regular',
    PRACTICE_QUIZ_DEMO: 'practice_quiz_demo',
    PRACTICE_RSVP_INTRO: 'practice_rsvp_intro',
    PRACTICE_RSVP: 'practice_rsvp',
    PRACTICE_DONE: 'practice_done',
    TRIAL_INTRO: 'trial_intro',
    TIMED: 'timed',
    RSVP: 'rsvp',
    QUIZ: 'quiz',
    SAVING: 'saving',
    DONE: 'done'
});

const stage = ref(Stage.START);

// Splits a passage's raw text into paragraph-sized chunks for static
// display (the timed-trial passage and the practice regular-reading text),
// flagging short, unpunctuated lines as probable section headings — e.g.
// "Speed dating" or "Lock and key party" in a passage broken into named
// sections — so they can be styled distinctly instead of just running
// together with the body text at the same weight and spacing.
function splitParagraphs(text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line.length > 0)
        .map((line) => {
            const wordCount = line.split(/\s+/).length;
            const looksLikeHeading = wordCount <= 5 && !/[.!?"')]$/.test(line);
            return { text: line, isHeading: looksLikeHeading };
        });
}

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

let runStartTime = null;

function beginPractice() {
    runStartTime = Date.now();
    stage.value = Stage.PRACTICE_REGULAR;
}

// ----- practice walkthrough: regular reading -> quiz demo -> rsvp intro ->
// rsvp, each a deliberate single step so a first-time participant sees every
// mechanic once, unscored, before the real trials begin -----

const PRACTICE_WPM = 100;
const PRACTICE_TEXT =
    "This experiment tests how well people understand text shown using a technique called RSVP, or rapid serial visual presentation. Instead of reading a full page, words appear one at a time, right here on the screen, at a fixed pace you don't control. Today, you'll read several short passages this way, at a couple different speeds, and after each one you'll answer a few comprehension questions. You'll also read some passages normally, but with a time limit. Just read naturally and answer as best you can. This practice round starts with a regular passage, just like the one you're reading now.";

function onPracticeRegularContinue() {
    stage.value = Stage.PRACTICE_QUIZ_DEMO;
}

// A one-off, non-scored demo of the quiz UI — separate from the real quiz's
// selectedOption so answering it can't leak into an actual trial.
const DEMO_QUESTION = {
    question: 'Questions will pop up like this after each passage.',
    options: {
        A: 'Pick this answer'
    }
};
const demoSelectedOption = ref(null);

function onDemoQuestionNext() {
    stage.value = Stage.PRACTICE_RSVP_INTRO;
}

function onRsvpIntroContinue() {
    stage.value = Stage.PRACTICE_RSVP;
}

// 100 wpm is slow enough that a full passage would drag on as a demo, so
// the rsvp practice step is just one short sentence.
const RSVP_DEMO_TEXT = 'This is what RSVP looks like.';

function onPracticeRsvpFinished() {
    stage.value = Stage.PRACTICE_DONE;
}

// ----- main trials: fixed ascending speed order, timed then rsvp at each -----

const MAIN_SPEEDS = [250, 450];

// Rough per-trial duration estimates for the start-screen primer, derived
// from the actual pool's average word count/question count rather than a
// guessed number — reading time is exact (wordCount/wpm), quiz time is a
// rough 10s/question guess. Individual trials vary with whichever passage
// gets drawn, so this is an estimate, not a promise.
const AVG_WORD_COUNT = passages.reduce((sum, p) => sum + p.text.trim().split(/\s+/).length, 0) / passages.length;
const AVG_QUESTIONS_PER_PASSAGE = passages.reduce((sum, p) => sum + p.questions.length, 0) / passages.length;
const SECONDS_PER_QUESTION_ESTIMATE = 10;
const PRACTICE_MINUTES_ESTIMATE = 2;

function estimateTrialMinutes(wpm) {
    const readSeconds = (AVG_WORD_COUNT / wpm) * 60;
    const quizSeconds = AVG_QUESTIONS_PER_PASSAGE * SECONDS_PER_QUESTION_ESTIMATE;
    return (readSeconds + quizSeconds) / 60;
}

// One row per main trial, in the same fixed order the run actually uses —
// regular reading then rsvp at each speed, ascending — for the start
// screen's trial-by-trial breakdown.
const trialPreview = MAIN_SPEEDS.flatMap((wpm, i) => [
    { label: `Trial ${i * 2 + 1} — Regular Reading @ ${wpm} wpm`, minutes: estimateTrialMinutes(wpm) },
    { label: `Trial ${i * 2 + 2} — RSVP @ ${wpm} wpm`, minutes: estimateTrialMinutes(wpm) }
]);

// Total primer estimate — practice plus every trial above — so this can't
// silently drift out of sync with MAIN_SPEEDS or trialPreview the way a
// hardcoded "~10-15 min" string could.
const totalMinutesEstimate = PRACTICE_MINUTES_ESTIMATE + trialPreview.reduce((sum, t) => sum + t.minutes, 0);

// One passage per trial (timed + rsvp, at each speed), drawn
// without replacement so no passage repeats within a run.
function buildMainTrials(pool) {
    const drawn = shuffle(pool).slice(0, MAIN_SPEEDS.length * 2);
    let cursor = 0;
    const trials = [];
    for (const wpm of MAIN_SPEEDS) {
        trials.push({ mode: 'timed', wpm, passage: drawn[cursor++] });
        trials.push({ mode: 'rsvp', wpm, passage: drawn[cursor++] });
    }
    return trials;
}

const trials = ref([]);
const currentTrialIndex = ref(0);
const currentTrial = computed(() => trials.value[currentTrialIndex.value]);

// Finished trial records accumulate here as the run progresses, then get
// bundled into one Firestore write at the very end (see finalizeRun).
const completedTrials = ref([]);

// Timestamps for the current trial's reading stage, captured via Reader's
// "started"/"finished" events (rsvp) or the countdown's own start/end
// (timed). Plain vars, not refs — nothing in the template reacts to these.
let trialStartTime = null;
let trialEndTime = null;

function beginMainTrials() {
    trials.value = buildMainTrials(passages);
    currentTrialIndex.value = 0;
    completedTrials.value = [];
    showTrialIntro();
}

// Shown before every main trial (timed or rsvp) so a participant always
// knows what's coming next — which trial number, which mode, and its time
// limit or wpm — rather than being dropped straight into it.
function showTrialIntro() {
    stage.value = Stage.TRIAL_INTRO;
}

function startCurrentTrial() {
    const trial = currentTrial.value;
    if (trial.mode === 'rsvp') {
        stage.value = Stage.RSVP;
    } else {
        stage.value = Stage.TIMED;
        startTimedCountdown(trial);
    }
}

function onRsvpTrialStarted() {
    trialStartTime = Date.now();
}

function onRsvpTrialFinished() {
    trialEndTime = Date.now();
    goToQuiz();
}

// ----- timed (non-RSVP) reading trial: static text + countdown -----

const timedSecondsRemaining = ref(0);
let timedIntervalId = null;

// Same duration a timed trial's countdown will start at — factored out so
// the TRIAL_INTRO screen can preview it before the countdown actually
// starts (see upcomingTimedDisplay below).
function computeTimedSeconds(trial) {
    const wordCount = trial.passage.text.trim().split(/\s+/).length;
    return Math.max(1, Math.round((wordCount / trial.wpm) * 60));
}

function formatSeconds(seconds) {
    const s = Math.max(0, seconds);
    const minutes = Math.floor(s / 60);
    const secs = s % 60;
    return `${minutes}:${String(secs).padStart(2, '0')}`;
}

function startTimedCountdown(trial) {
    const totalSeconds = computeTimedSeconds(trial);
    timedSecondsRemaining.value = totalSeconds;
    trialStartTime = Date.now();

    clearInterval(timedIntervalId);
    timedIntervalId = setInterval(() => {
        timedSecondsRemaining.value--;
        if (timedSecondsRemaining.value <= 0) {
            finishTimedTrial('timedOut');
        }
    }, 1000);
}

// outcome is 'finishedEarly' (participant clicked Done) or 'timedOut' (the
// countdown reached zero) — recorded on the trial itself since RSVP has no
// equivalent notion and it's a useful axis for comparing the two modes.
function finishTimedTrial(outcome = 'finishedEarly') {
    clearInterval(timedIntervalId);
    timedIntervalId = null;
    trialEndTime = Date.now();
    currentTrial.value.timedOutcome = outcome;
    goToQuiz();
}

onUnmounted(() => clearInterval(timedIntervalId));

const timedTimeDisplay = computed(() => formatSeconds(timedSecondsRemaining.value));

// Preview of a timed trial's time limit, shown on its TRIAL_INTRO screen
// before the countdown actually starts.
const upcomingTimedDisplay = computed(() => {
    if (!currentTrial.value || currentTrial.value.mode !== 'timed') {
        return '';
    }
    return formatSeconds(computeTimedSeconds(currentTrial.value));
});

// ----- one-question-at-a-time comprehension quiz (shared by rsvp + timed) -----

const currentQuestionIndex = ref(0);
const selectedOption = ref(null);
const questionAnswers = ref([]);
let questionShownAt = null;

const currentQuizQuestions = computed(() => currentTrial.value?.passage.questions ?? []);
const currentQuestion = computed(() => currentQuizQuestions.value[currentQuestionIndex.value]);
const isLastQuestionOfTrial = computed(() => currentQuestionIndex.value === currentQuizQuestions.value.length - 1);
const isFinalQuestionOfRun = computed(() => isLastQuestionOfTrial.value && currentTrialIndex.value === trials.value.length - 1);

function goToQuiz() {
    currentQuestionIndex.value = 0;
    selectedOption.value = null;
    questionAnswers.value = [];
    questionShownAt = Date.now();
    stage.value = Stage.QUIZ;
}

function submitQuestion() {
    if (selectedOption.value === null) {
        return;
    }

    const question = currentQuestion.value;
    const optionEntries = Object.entries(question.options);
    questionAnswers.value.push({
        question: question.question,
        selectedOption: optionEntries[selectedOption.value]?.[1] ?? null,
        correctOption: optionEntries[question.correctIndex]?.[1] ?? null,
        isCorrect: selectedOption.value === question.correctIndex,
        timeMs: Date.now() - questionShownAt
    });

    if (isLastQuestionOfTrial.value) {
        finishTrialQuiz();
    } else {
        currentQuestionIndex.value++;
        selectedOption.value = null;
        questionShownAt = Date.now();
    }
}

// ----- per-trial derived stats, aimed at comparing rsvp vs. timed reading -----

// Precomputed once the run finishes so the DONE screen's analytics and the
// Firestore write always agree, rather than each recomputing separately.
const finalComparison = ref(null);

const overallAccuracyPct = computed(() => {
    const totalCorrect = completedTrials.value.reduce((sum, t) => sum + t.quiz.correctCount, 0);
    const totalQuestions = completedTrials.value.reduce((sum, t) => sum + t.quiz.totalQuestions, 0);
    return totalQuestions ? (totalCorrect / totalQuestions) * 100 : 0;
});

function finishTrialQuiz() {
    const trial = currentTrial.value;
    const correctCount = questionAnswers.value.filter((a) => a.isCorrect).length;
    const totalQuestions = questionAnswers.value.length;
    const accuracyPct = totalQuestions ? (correctCount / totalQuestions) * 100 : 0;
    const avgTimeToAnswerMs = totalQuestions
        ? questionAnswers.value.reduce((sum, a) => sum + a.timeMs, 0) / totalQuestions
        : 0;
    const readingDurationMs = trialEndTime - trialStartTime;
    // Comprehension per second of reading — lets a fast-but-shallow read and
    // a slow-but-thorough one be compared on the same scale.
    const comprehensionEfficiency = readingDurationMs > 0 ? accuracyPct / (readingDurationMs / 1000) : 0;

    completedTrials.value.push({
        position: currentTrialIndex.value,
        mode: trial.mode,
        wpm: trial.wpm,
        passageId: trial.passage.id,
        wordCount: trial.passage.text.trim().split(/\s+/).length,
        readingDurationMs,
        timedOutcome: trial.mode === 'timed' ? trial.timedOutcome : null,
        accuracyPct,
        comprehensionEfficiency,
        avgTimeToAnswerMs,
        quiz: {
            totalQuestions,
            correctCount,
            questions: [...questionAnswers.value]
        }
    });

    if (currentTrialIndex.value < trials.value.length - 1) {
        currentTrialIndex.value++;
        showTrialIntro();
    } else {
        finalComparison.value = computeComparison(completedTrials.value);
        stage.value = Stage.SAVING;
        finalizeRun();
    }
}

// Run-level rsvp-vs-timed comparison, precomputed so analysis doesn't have
// to re-derive it from the raw trial list every time.
function computeComparison(finishedTrials) {
    const mean = (list, key) => (list.length ? list.reduce((sum, t) => sum + t[key], 0) / list.length : 0);

    const rsvpTrials = finishedTrials.filter((t) => t.mode === 'rsvp');
    const timedTrials = finishedTrials.filter((t) => t.mode === 'timed');
    const finishedEarlyCount = timedTrials.filter((t) => t.timedOutcome === 'finishedEarly').length;

    return {
        rsvp: {
            meanAccuracyPct: mean(rsvpTrials, 'accuracyPct'),
            meanEfficiency: mean(rsvpTrials, 'comprehensionEfficiency'),
            meanTimeToAnswerMs: mean(rsvpTrials, 'avgTimeToAnswerMs')
        },
        timed: {
            meanAccuracyPct: mean(timedTrials, 'accuracyPct'),
            meanEfficiency: mean(timedTrials, 'comprehensionEfficiency'),
            meanTimeToAnswerMs: mean(timedTrials, 'avgTimeToAnswerMs'),
            completionRatePct: timedTrials.length ? (finishedEarlyCount / timedTrials.length) * 100 : 0
        },
        accuracyDeltaRsvpMinusTimed: mean(rsvpTrials, 'accuracyPct') - mean(timedTrials, 'accuracyPct'),
        bySpeed: MAIN_SPEEDS.map((wpm) => ({
            wpm,
            rsvpAccuracyPct: mean(
                rsvpTrials.filter((t) => t.wpm === wpm),
                'accuracyPct'
            ),
            timedAccuracyPct: mean(
                timedTrials.filter((t) => t.wpm === wpm),
                'accuracyPct'
            )
        }))
    };
}

// ----- save the whole run as one Firestore document -----

const isSaving = ref(false);
const saveError = ref('');

async function finalizeRun() {
    isSaving.value = true;
    saveError.value = '';
    const runEndTime = Date.now();

    const runRecord = {
        runStartedAt: runStartTime,
        runEndedAt: runEndTime,
        totalElapsedMs: runEndTime - runStartTime,
        trials: completedTrials.value,
        comparison: finalComparison.value,
        // Lightweight, non-identifying environment context — useful for
        // filtering (e.g. mobile vs. desktop) without asking the participant
        // anything.
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
    <!-- Fades between stages instead of the previous instant, jarring swap —
         most noticeable right after an RSVP passage finishes and the screen
         cuts straight to the next one. mode="out-in" waits for the old
         stage to fully fade out before the new one fades in, so nothing
         overlaps mid-transition. -->
    <Transition name="stage-fade" mode="out-in">
    <div :key="stage">
    <!-- start screen: a primer covering what the study is, what to expect,
         and where the passages come from, so nothing is a surprise before
         hitting Begin -->
    <div v-if="stage === Stage.START" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10 text-left">
            <h2 class="mb-3 text-center text-2xl font-bold !text-ink">Reading Study</h2>
            <p class="mb-6 !text-ink-light">
                This study compares two ways of reading — <strong class="!text-ink">RSVP</strong> (words shown
                one at a time, at a fixed pace) and <strong class="!text-ink">regular reading</strong> (a normal
                passage, at your own pace, under a time limit) — to see how each affects comprehension. Each
                trial is followed by a few comprehension questions about what you just read.
            </p>

            <div class="mb-6 rounded-2xl border border-border bg-bg p-5">
                <p class="mb-3 text-xs font-semibold uppercase tracking-widest !text-ink-light">What to expect</p>
                <ul class="flex flex-col gap-2 text-sm">
                    <li class="flex items-baseline justify-between gap-4">
                        <span class="!text-ink">Practice walkthrough</span>
                        <span class="!text-ink-light">~{{ PRACTICE_MINUTES_ESTIMATE }} min</span>
                    </li>
                    <li
                        v-for="t in trialPreview"
                        :key="t.label"
                        class="flex items-baseline justify-between gap-4"
                    >
                        <span class="!text-ink">{{ t.label }}</span>
                        <span class="!text-ink-light shrink-0">~{{ t.minutes.toFixed(1) }} min</span>
                    </li>
                    <li class="flex items-baseline justify-between gap-4 border-t border-border pt-2 font-semibold">
                        <span class="!text-ink">Total</span>
                        <span class="!text-ink">~{{ Math.round(totalMinutesEstimate) }}–{{ Math.round(totalMinutesEstimate * 1.5) }} min</span>
                    </li>
                </ul>
            </div>

            <p class="mb-8 text-sm !text-ink-light">
                Passages are real reading-comprehension texts from
                <strong class="!text-ink">RACE</strong>, an academic dataset of English exam passages — not
                filler, so your answers reflect genuine comprehension.
            </p>

            <button class="btn-primary w-full" @click="beginPractice">Begin</button>
        </div>
    </div>

    <!-- practice: regular reading, using the same sample passage this text is drawn from -->
    <div v-else-if="stage === Stage.PRACTICE_REGULAR" class="mx-auto max-w-4xl px-5 pt-16 pb-5">
        <p class="mb-4 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Practice — Regular Reading
        </p>
        <div class="rounded-2xl border border-border bg-card p-6 !text-ink leading-relaxed">
            <p
                v-for="(para, i) in splitParagraphs(PRACTICE_TEXT)"
                :key="i"
                :class="para.isHeading ? 'mb-2 mt-5 font-display text-lg font-bold first:mt-0' : 'mb-4 last:mb-0'"
            >
                {{ para.text }}
            </p>
        </div>
        <button class="btn-primary w-full mt-6" @click="onPracticeRegularContinue">Continue</button>
    </div>

    <!-- practice: a one-off demo of the quiz UI, unscored -->
    <div v-else-if="stage === Stage.PRACTICE_QUIZ_DEMO" class="mx-auto max-w-2xl px-5 pt-16 pb-5">
        <p class="mb-2 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Practice — Questions
        </p>
        <p class="mb-6 text-center !text-ink-light">
            Questions will pop up like this after each passage. Pick an answer, then hit Next.
        </p>

        <div class="rounded-2xl border border-border bg-card p-6">
            <p class="mb-5 text-lg font-semibold !text-ink">{{ DEMO_QUESTION.question }}</p>
            <div class="flex flex-col gap-2">
                <label
                    v-for="(option, key, oi) in DEMO_QUESTION.options"
                    :key="key"
                    class="flex cursor-pointer items-center gap-3 rounded-xl border px-4 py-3 transition-colors hover:bg-ink/5"
                    :class="demoSelectedOption === oi ? 'border-ink bg-ink/10' : 'border-border'"
                >
                    <input type="radio" class="radio accent-ink" name="demo-quiz-option" :value="oi" v-model="demoSelectedOption" />
                    <span class="!text-ink">{{ option }}</span>
                </label>
            </div>
        </div>

        <button
            class="btn-primary w-full mt-6"
            :disabled="demoSelectedOption === null"
            @click="onDemoQuestionNext"
        >
            Next
        </button>
    </div>

    <!-- practice: rsvp intro -->
    <div v-else-if="stage === Stage.PRACTICE_RSVP_INTRO" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <h2 class="mb-3 text-2xl font-bold !text-ink">Now let's try RSVP</h2>
            <p class="mb-8 !text-ink-light">
                Words will appear one at a time, right in the middle of the screen, at a fixed pace you don't control.
            </p>
            <button class="btn-primary w-full" @click="onRsvpIntroContinue">Continue</button>
        </div>
    </div>

    <!-- practice: rsvp, a single short sentence since 100 wpm makes a full passage drag on -->
    <div v-else-if="stage === Stage.PRACTICE_RSVP" class="mx-auto max-w-4xl px-5 pt-16 pb-5">
        <p class="mb-4 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Practice — RSVP
        </p>
        <Reader
            :text="RSVP_DEMO_TEXT"
            :wpm="PRACTICE_WPM"
            :settings-modal="false"
            :min-wpm="60"
            :max-wpm="600"
            :wpm-step="20"
            :persist-progress="false"
            :track-stats="false"
            :lock-controls="true"
            @finished="onPracticeRsvpFinished"
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

    <!-- what's-next screen before every main trial: names the trial number,
         the mode, and its time limit or wpm, so nothing starts unannounced -->
    <div v-else-if="stage === Stage.TRIAL_INTRO" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <p class="mb-2 text-xs font-semibold uppercase tracking-widest !text-ink-light">
                Trial {{ currentTrialIndex + 1 }} of {{ trials.length }}
            </p>
            <h2 class="mb-3 text-2xl font-bold !text-ink">
                {{ currentTrial.mode === 'timed' ? 'Regular Reading' : 'RSVP' }}
            </h2>
            <p class="mb-8 !text-ink-light">
                <template v-if="currentTrial.mode === 'timed'">
                    You'll have {{ upcomingTimedDisplay }} to read the passage at your own pace. Hit Done when
                    you're finished, or it'll move on automatically once time runs out. Then you'll answer a
                    few questions about it.
                </template>
                <template v-else>
                    Words will appear one at a time at {{ currentTrial.wpm }} words per minute. Then you'll
                    answer a few questions about what you read.
                </template>
            </p>
            <button class="btn-primary w-full" @click="startCurrentTrial">Start</button>
        </div>
    </div>

    <!-- timed, normal-reading main trial -->
    <div v-else-if="stage === Stage.TIMED" class="mx-auto max-w-2xl px-5 pt-16 pb-5">
        <p class="mb-2 mt-2 text-center text-xs font-semibold uppercase tracking-widest !text-ink-light">
            Trial {{ currentTrialIndex + 1 }} of {{ trials.length }}
        </p>
        <p class="mb-6 text-center text-3xl font-bold !text-ink">{{ timedTimeDisplay }}</p>

        <div class="rounded-2xl border border-border bg-card p-6 !text-ink leading-relaxed">
            <p
                v-for="(para, i) in splitParagraphs(currentTrial.passage.text)"
                :key="i"
                :class="para.isHeading ? 'mb-2 mt-5 font-display text-lg font-bold first:mt-0' : 'mb-4 last:mb-0'"
            >
                {{ para.text }}
            </p>
        </div>

        <button class="btn-primary w-full mt-6" @click="finishTimedTrial()">Done</button>
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
            @started="onRsvpTrialStarted"
            @finished="onRsvpTrialFinished"
        />
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
                    v-for="(option, key, oi) in currentQuestion.options"
                    :key="key"
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

    <!-- end screen — a quick, participant-facing look at their own results -->
    <div v-else-if="stage === Stage.DONE" class="mx-auto max-w-xl px-5 pt-16 pb-5 text-center">
        <div class="mt-16 rounded-3xl border border-border bg-card p-10">
            <h2 class="mb-3 text-3xl font-bold !text-ink">Thanks, you're done!</h2>
            <p class="mb-6 !text-ink-light">Here's a quick look at how you did.</p>

            <div v-if="finalComparison" class="rounded-2xl border border-border bg-bg p-5 text-left">
                <div class="mb-4 flex items-baseline justify-between">
                    <span class="!text-ink-light">Overall accuracy</span>
                    <span class="font-mono text-xl font-bold !text-ink">{{ overallAccuracyPct.toFixed(0) }}%</span>
                </div>
                <div class="grid grid-cols-2 gap-4 border-t border-border pt-4">
                    <div>
                        <p class="text-xs font-semibold uppercase tracking-widest !text-ink-light">Regular Reading</p>
                        <p class="font-mono text-lg font-bold !text-ink">{{ finalComparison.timed.meanAccuracyPct.toFixed(0) }}%</p>
                    </div>
                    <div>
                        <p class="text-xs font-semibold uppercase tracking-widest !text-ink-light">RSVP</p>
                        <p class="font-mono text-lg font-bold !text-ink">{{ finalComparison.rsvp.meanAccuracyPct.toFixed(0) }}%</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    </div>
    </Transition>
</template>

<style scoped>
.stage-fade-enter-active,
.stage-fade-leave-active {
    transition: opacity 0.18s ease;
}
.stage-fade-enter-from,
.stage-fade-leave-to {
    opacity: 0;
}
</style>
