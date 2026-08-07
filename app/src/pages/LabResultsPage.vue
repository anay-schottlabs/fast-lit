<script setup>
import { ref, computed, onMounted } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, getDocs } from 'firebase/firestore';
import Header from '../components/Header.vue';

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
                passageId: trial.passageId,
                wpm: trial.wpm,
                achievedWpm: trial.achievedWpm,
                wordCount: trial.wordCount,
                actualDurationMs: trial.actualDurationMs,
                expectedDurationMs: trial.expectedDurationMs,
                durationMismatchFlag: trial.durationMismatchFlag,
                accuracyPct: trial.quiz?.accuracyPct ?? 0,
                correctCount: trial.quiz?.correctCount ?? 0,
                totalQuestions: trial.quiz?.totalQuestions ?? 0,
                quizDurationMs: trial.quiz?.quizDurationMs ?? 0,
                questions: trial.quiz?.questions ?? [],
                runTotalElapsedMs: run.totalElapsedMs,
                runTotalReadingMs: run.totalReadingMs,
                runTotalQuizMs: run.totalQuizMs,
                runOverallAccuracyPct: run.overallAccuracyPct,
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
    { key: 'passageId', label: 'Passage' },
    { key: 'wpm', label: 'WPM' },
    { key: 'achievedWpm', label: 'Achieved WPM' },
    { key: 'accuracyPct', label: 'Accuracy %' },
    { key: 'actualDurationMs', label: 'Reading (ms)' },
    { key: 'expectedDurationMs', label: 'Expected (ms)' },
    { key: 'durationMismatchFlag', label: 'Flag' },
    { key: 'quizDurationMs', label: 'Quiz (ms)' }
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
        if (typeof av === 'boolean' || typeof bv === 'boolean') {
            av = av ? 1 : 0;
            bv = bv ? 1 : 0;
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

// ----- average comprehension per wpm bucket -----

const wpmBuckets = computed(() => {
    const buckets = new Map();
    for (const r of rows.value) {
        if (!buckets.has(r.wpm)) {
            buckets.set(r.wpm, { wpm: r.wpm, trialCount: 0, accuracySum: 0 });
        }
        const bucket = buckets.get(r.wpm);
        bucket.trialCount++;
        bucket.accuracySum += r.accuracyPct;
    }
    return [...buckets.values()]
        .map((b) => ({ ...b, avgAccuracyPct: b.accuracySum / b.trialCount }))
        .sort((a, b) => a.wpm - b.wpm);
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
    'runId', 'position', 'passageId', 'wpm', 'achievedWpm', 'wordCount',
    'actualDurationMs', 'expectedDurationMs', 'durationMismatchFlag',
    'accuracyPct', 'correctCount', 'totalQuestions', 'quizDurationMs', 'questions',
    'runTotalElapsedMs', 'runTotalReadingMs', 'runTotalQuizMs', 'runOverallAccuracyPct', 'userAgent'
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
    <div class="mx-auto max-w-6xl p-5">
        <Header pageName="Lab Results" />

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
            <!-- average comprehension per speed bucket -->
            <div class="mt-6 rounded-2xl border border-border bg-card card-shadow p-5">
                <h2 class="mb-3 text-lg font-semibold !text-ink">Average Accuracy by Speed</h2>
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-sm">
                        <thead>
                            <tr class="!text-ink-light">
                                <th class="py-1 pr-6">WPM</th>
                                <th class="py-1 pr-6">Trials</th>
                                <th class="py-1 pr-6">Avg. Accuracy</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="bucket in wpmBuckets" :key="bucket.wpm" class="border-t border-border">
                                <td class="py-2 pr-6 font-mono !text-ink">{{ bucket.wpm }}</td>
                                <td class="py-2 pr-6 !text-ink">{{ bucket.trialCount }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ bucket.avgAccuracyPct.toFixed(1) }}%</td>
                            </tr>
                            <tr v-if="wpmBuckets.length === 0">
                                <td class="py-2 !text-ink-light" colspan="3">No trials yet.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- raw trial records -->
            <div class="mt-6 rounded-2xl border border-border bg-card card-shadow p-5">
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
                                <td class="py-2 pr-6 !text-ink">{{ row.passageId }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.wpm }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.achievedWpm }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.accuracyPct.toFixed(0) }}% ({{ row.correctCount }}/{{ row.totalQuestions }})</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.actualDurationMs }}</td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.expectedDurationMs }}</td>
                                <td class="py-2 pr-6">
                                    <span v-if="row.durationMismatchFlag" class="rounded-full bg-error/10 px-2 py-0.5 text-xs text-error">flagged</span>
                                </td>
                                <td class="py-2 pr-6 font-mono !text-ink">{{ row.quizDurationMs }}</td>
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
