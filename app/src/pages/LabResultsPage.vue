<script setup>
import { ref, computed, onMounted } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, getDocs } from 'firebase/firestore';

const runs = ref([]);
const isLoading = ref(true);
const loadError = ref('');

onMounted(async () => {
    try {
        const snapshot = await getDocs(collection(db, 'labRuns'));
        runs.value = snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }));
    } catch (err) {
        console.error('Failed to load lab runs:', err);
        loadError.value = 'Could not load results — check your connection and try again.';
    } finally {
        isLoading.value = false;
    }
});

// ----- flatten runs -> one row per trial, for a sortable table and CSV export -----

const rows = computed(() => {
    const flattened = [];
    for (const run of runs.value) {
        for (const trial of run.trials ?? []) {
            flattened.push({
                runId: run.id,
                runCreatedAt: run.createdAt,
                position: trial.position,
                mode: trial.mode,
                passageId: trial.passageId,
                wpm: trial.wpm,
                wordCount: trial.wordCount,
                readingDurationMs: trial.readingDurationMs,
                timedOutcome: trial.timedOutcome,
                accuracyPct: trial.accuracyPct ?? 0,
                comprehensionEfficiency: trial.comprehensionEfficiency ?? 0,
                avgTimeToAnswerMs: trial.avgTimeToAnswerMs ?? 0,
                correctCount: trial.quiz?.correctCount ?? 0,
                totalQuestions: trial.quiz?.totalQuestions ?? 0,
                questions: trial.quiz?.questions ?? [],
                runTotalElapsedMs: run.totalElapsedMs,
                userAgent: run.userAgent
            });
        }
    }
    return flattened;
});

// ----- sorting -----

const sortKey = ref('runCreatedAt');
const sortDir = ref('desc');

const sortableColumns = [
    { key: 'runId', label: 'Run' },
    { key: 'position', label: 'Order' },
    { key: 'mode', label: 'Mode' },
    { key: 'passageId', label: 'Passage' },
    { key: 'wpm', label: 'WPM' },
    { key: 'accuracyPct', label: 'Accuracy %' },
    { key: 'comprehensionEfficiency', label: 'Efficiency' },
    { key: 'readingDurationMs', label: 'Reading (ms)' },
    { key: 'avgTimeToAnswerMs', label: 'Avg. Time/Q (ms)' },
    { key: 'timedOutcome', label: 'Outcome' }
];

function setSort(key) {
    if (sortKey.value === key) {
        sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc';
    } else {
        sortKey.value = key;
        sortDir.value = 'asc';
    }
}

function toMillis(value) {
    if (!value) return 0;
    return typeof value.toMillis === 'function' ? value.toMillis() : Number(value) || 0;
}

const sortedRows = computed(() => {
    const sorted = [...rows.value];
    sorted.sort((a, b) => {
        let av = a[sortKey.value];
        let bv = b[sortKey.value];

        if (sortKey.value === 'runCreatedAt') {
            av = toMillis(a.runCreatedAt);
            bv = toMillis(b.runCreatedAt);
        }
        if (typeof av === 'string' || typeof bv === 'string') {
            av = (av ?? '').toString();
            bv = (bv ?? '').toString();
            return sortDir.value === 'asc' ? av.localeCompare(bv) : bv.localeCompare(av);
        }

        av = av ?? 0;
        bv = bv ?? 0;
        return sortDir.value === 'asc' ? av - bv : bv - av;
    });
    return sorted;
});

// ----- rsvp vs. timed comparison, computed directly from every loaded trial
// (not just each run's own precomputed comparison field) so it reflects
// every run at once -----

function mean(list, key) {
    return list.length ? list.reduce((sum, r) => sum + r[key], 0) / list.length : 0;
}

const overallComparison = computed(() => {
    const rsvpRows = rows.value.filter((r) => r.mode === 'rsvp');
    const timedRows = rows.value.filter((r) => r.mode === 'timed');
    const finishedEarlyCount = timedRows.filter((r) => r.timedOutcome === 'finishedEarly').length;

    return {
        rsvp: {
            trialCount: rsvpRows.length,
            meanAccuracyPct: mean(rsvpRows, 'accuracyPct'),
            meanEfficiency: mean(rsvpRows, 'comprehensionEfficiency'),
            meanTimeToAnswerMs: mean(rsvpRows, 'avgTimeToAnswerMs')
        },
        timed: {
            trialCount: timedRows.length,
            meanAccuracyPct: mean(timedRows, 'accuracyPct'),
            meanEfficiency: mean(timedRows, 'comprehensionEfficiency'),
            meanTimeToAnswerMs: mean(timedRows, 'avgTimeToAnswerMs'),
            completionRatePct: timedRows.length ? (finishedEarlyCount / timedRows.length) * 100 : 0
        }
    };
});

const bySpeedComparison = computed(() => {
    const speeds = [...new Set(rows.value.map((r) => r.wpm))].sort((a, b) => a - b);
    return speeds.map((wpm) => {
        const rsvpRows = rows.value.filter((r) => r.wpm === wpm && r.mode === 'rsvp');
        const timedRows = rows.value.filter((r) => r.wpm === wpm && r.mode === 'timed');
        return {
            wpm,
            rsvpAccuracyPct: mean(rsvpRows, 'accuracyPct'),
            rsvpCount: rsvpRows.length,
            timedAccuracyPct: mean(timedRows, 'accuracyPct'),
            timedCount: timedRows.length
        };
    });
});

// ----- CSV export -----

function csvEscape(value) {
    if (value === null || value === undefined) {
        return '';
    }
    if (Array.isArray(value) || typeof value === 'object') {
        value = JSON.stringify(value);
    }
    const str = String(value);
    if (/[",\n]/.test(str)) {
        return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
}

const csvColumns = [
    'runId', 'position', 'mode', 'passageId', 'wpm', 'wordCount',
    'readingDurationMs', 'timedOutcome',
    'accuracyPct', 'comprehensionEfficiency', 'avgTimeToAnswerMs',
    'correctCount', 'totalQuestions', 'questions',
    'runTotalElapsedMs', 'userAgent'
];

function downloadCsv() {
    const lines = [csvColumns.join(',')];
    for (const r of rows.value) {
        lines.push(csvColumns.map((col) => csvEscape(r[col])).join(','));
    }
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `lab-results-${Date.now()}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}
</script>

<template>
    <div class="mx-auto max-w-6xl p-5 pt-16">
        <h1 class="font-display text-3xl font-bold text-ink">Lab Results</h1>

        <div class="mt-6 flex items-center justify-between">
            <p class="text-sm !text-ink-light">
                {{ runs.length }} run{{ runs.length === 1 ? '' : 's' }}, {{ rows.length }} trial{{ rows.length === 1 ? '' : 's' }} loaded
            </p>
            <button class="btn-primary" :disabled="isLoading || rows.length === 0" @click="downloadCsv">
                Download as CSV
            </button>
        </div>

        <p v-if="isLoading" class="mt-10 text-center !text-ink-light">Loading…</p>
        <p v-else-if="loadError" class="mt-10 text-center text-error">{{ loadError }}</p>

        <template v-else>
            <!-- rsvp vs. timed, overall -->
            <div class="mt-6 rounded-2xl border border-border bg-card p-5">
                <h2 class="mb-3 text-lg font-semibold !text-ink">RSVP vs. Timed Reading</h2>
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-sm">
                        <thead>
                            <tr class="!text-ink-light">
                                <th class="py-1 pr-6">Mode</th>
                                <th class="py-1 pr-6">Trials</th>
                                <th class="py-1 pr-6">Avg. Accuracy</th>
                                <th class="py-1 pr-6">Avg. Efficiency</th>
                                <th class="py-1 pr-6">Avg. Time/Question</th>
                                <th class="py-1 pr-6">Completion Rate</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="border-t border-border">
                                <td class="py-2 pr-6 !text-ink">RSVP</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.rsvp.trialCount }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.rsvp.meanAccuracyPct.toFixed(1) }}%</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.rsvp.meanEfficiency.toFixed(2) }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.rsvp.meanTimeToAnswerMs.toFixed(0) }}ms</td>
                                <td class="py-2 pr-6 !text-ink-light">—</td>
                            </tr>
                            <tr class="border-t border-border">
                                <td class="py-2 pr-6 !text-ink">Timed (normal reading)</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.timed.trialCount }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.timed.meanAccuracyPct.toFixed(1) }}%</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.timed.meanEfficiency.toFixed(2) }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.timed.meanTimeToAnswerMs.toFixed(0) }}ms</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ overallComparison.timed.completionRatePct.toFixed(0) }}%</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <p class="mt-3 text-xs !text-ink-light">
                    Efficiency is accuracy % per second of reading time. Completion rate is the share of timed
                    trials finished via "Done" rather than cut off by the countdown — RSVP has no equivalent
                    since it always runs to completion.
                </p>
            </div>

            <!-- rsvp vs. timed, by speed -->
            <div class="mt-6 rounded-2xl border border-border bg-card p-5">
                <h2 class="mb-3 text-lg font-semibold !text-ink">Accuracy by Speed</h2>
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-sm">
                        <thead>
                            <tr class="!text-ink-light">
                                <th class="py-1 pr-6">WPM</th>
                                <th class="py-1 pr-6">RSVP Accuracy</th>
                                <th class="py-1 pr-6">Timed Accuracy</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="bucket in bySpeedComparison" :key="bucket.wpm" class="border-t border-border">
                                <td class="py-2 pr-6 font-mono !text-ink">{{ bucket.wpm }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ bucket.rsvpAccuracyPct.toFixed(1) }}% ({{ bucket.rsvpCount }})</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ bucket.timedAccuracyPct.toFixed(1) }}% ({{ bucket.timedCount }})</td>
                            </tr>
                            <tr v-if="bySpeedComparison.length === 0">
                                <td class="py-2 !text-ink-light" colspan="3">No trials yet.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- raw trial records -->
            <div class="mt-6 rounded-2xl border border-border bg-card p-5">
                <h2 class="mb-3 text-lg font-semibold !text-ink">All Trials</h2>
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-sm">
                        <thead>
                            <tr class="!text-ink-light">
                                <th
                                    v-for="col in sortableColumns"
                                    :key="col.key"
                                    class="cursor-pointer select-none whitespace-nowrap py-1 pr-6 hover:!text-ink"
                                    @click="setSort(col.key)"
                                >
                                    {{ col.label }}
                                    <span v-if="sortKey === col.key">{{ sortDir === 'asc' ? '▲' : '▼' }}</span>
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="row in sortedRows" :key="row.runId + '-' + row.position" class="border-t border-border">
                                <td class="py-2 pr-6 font-mono text-xs !text-ink-light">{{ row.runId.slice(0, 6) }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.position }}</td>
                                <td class="py-2 pr-6 !text-ink">{{ row.mode }}</td>
                                <td class="py-2 pr-6 !text-ink">{{ row.passageId }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.wpm }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.accuracyPct.toFixed(0) }}% ({{ row.correctCount }}/{{ row.totalQuestions }})</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.comprehensionEfficiency.toFixed(2) }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.readingDurationMs }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.avgTimeToAnswerMs.toFixed(0) }}</td>
                                <td class="py-2 pr-6 !text-ink-light">{{ row.timedOutcome ?? '—' }}</td>
                            </tr>
                            <tr v-if="sortedRows.length === 0">
                                <td class="py-2 !text-ink-light" colspan="10">No trials yet.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </template>
    </div>
</template>

<style scoped></style>
