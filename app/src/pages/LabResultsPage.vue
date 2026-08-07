<script setup>
import { ref, computed, onMounted } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, getDocs } from 'firebase/firestore';
import Header from '../components/Header.vue';

const records = ref([]);
const isLoading = ref(true);
const loadError = ref('');

// Firestore Timestamp objects (from serverTimestamp()) expose .toDate(); a
// still-pending local write can hand back null instead, so guard both.
function toDate(value) {
    if (!value) {
        return null;
    }
    return typeof value.toDate === 'function' ? value.toDate() : new Date(value);
}

onMounted(async () => {
    try {
        const snapshot = await getDocs(collection(db, 'labTrials'));
        records.value = snapshot.docs.map((docSnap) => {
            const data = docSnap.data();
            return {
                id: docSnap.id,
                ...data,
                timestampDate: toDate(data.timestamp)
            };
        });
    } catch (err) {
        console.error('Failed to load lab trial records:', err);
        loadError.value = 'Could not load trial records — check your connection and try again.';
    } finally {
        isLoading.value = false;
    }
});

// ----- sorting -----

const sortKey = ref('timestampDate');
const sortDir = ref('desc');

const sortableColumns = [
    { key: 'participantId', label: 'Participant' },
    { key: 'wpm', label: 'WPM' },
    { key: 'passageId', label: 'Passage' },
    { key: 'trialOrderIndex', label: 'Order' },
    { key: 'comprehensionPct', label: 'Comprehension %' },
    { key: 'actualDurationMs', label: 'Actual (ms)' },
    { key: 'expectedDurationMs', label: 'Expected (ms)' },
    { key: 'durationMismatchFlag', label: 'Flag' },
    { key: 'quizDurationMs', label: 'Quiz (ms)' },
    { key: 'timestampDate', label: 'Recorded' }
];

function setSort(key) {
    if (sortKey.value === key) {
        sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc';
    } else {
        sortKey.value = key;
        sortDir.value = 'asc';
    }
}

const rows = computed(() => {
    return records.value.map((r) => ({
        ...r,
        comprehensionPct: r.totalQuestions ? (r.correctCount / r.totalQuestions) * 100 : 0
    }));
});

const sortedRows = computed(() => {
    const sorted = [...rows.value];
    sorted.sort((a, b) => {
        let av = a[sortKey.value];
        let bv = b[sortKey.value];

        if (av instanceof Date || bv instanceof Date) {
            av = av ? av.getTime() : 0;
            bv = bv ? bv.getTime() : 0;
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
            buckets.set(r.wpm, { wpm: r.wpm, trialCount: 0, comprehensionSum: 0 });
        }
        const bucket = buckets.get(r.wpm);
        bucket.trialCount++;
        bucket.comprehensionSum += r.comprehensionPct;
    }
    return [...buckets.values()]
        .map((b) => ({ ...b, avgComprehensionPct: b.comprehensionSum / b.trialCount }))
        .sort((a, b) => a.wpm - b.wpm);
});

// ----- CSV export -----

const csvColumns = [
    'sessionId', 'participantId', 'passageId', 'wpm', 'trialOrderIndex',
    'actualStartTime', 'actualEndTime', 'actualDurationMs', 'expectedDurationMs',
    'durationMismatchFlag', 'quizAnswers', 'correctCount', 'totalQuestions',
    'quizDurationMs', 'timestampDate'
];

function csvEscape(value) {
    if (value === null || value === undefined) {
        return '';
    }
    if (Array.isArray(value)) {
        value = value.join('|');
    }
    if (value instanceof Date) {
        value = value.toISOString();
    }
    const str = String(value);
    if (/[",\n]/.test(str)) {
        return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
}

function downloadCsv() {
    const lines = [csvColumns.join(',')];
    for (const r of records.value) {
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
            <p class="text-sm text-white/60">{{ records.length }} trial record{{ records.length === 1 ? '' : 's' }} loaded</p>
            <button class="btn-red" :disabled="isLoading || records.length === 0" @click="downloadCsv">
                Download as CSV
            </button>
        </div>

        <p v-if="isLoading" class="mt-10 text-center text-white/50">Loading…</p>
        <p v-else-if="loadError" class="mt-10 text-center text-red-light">{{ loadError }}</p>

        <template v-else>
            <!-- average comprehension per speed bucket -->
            <div class="mt-6 rounded-2xl border border-white/10 bg-white/5 p-5 shadow-2xl shadow-black/40">
                <h2 class="mb-3 text-lg font-semibold">Average Comprehension by Speed</h2>
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-sm">
                        <thead>
                            <tr class="text-white/50">
                                <th class="py-1 pr-6">WPM</th>
                                <th class="py-1 pr-6">Trials</th>
                                <th class="py-1 pr-6">Avg. Comprehension</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="bucket in wpmBuckets" :key="bucket.wpm" class="border-t border-white/10">
                                <td class="py-2 pr-6 font-mono">{{ bucket.wpm }}</td>
                                <td class="py-2 pr-6">{{ bucket.trialCount }}</td>
                                <td class="py-2 pr-6 font-mono">{{ bucket.avgComprehensionPct.toFixed(1) }}%</td>
                            </tr>
                            <tr v-if="wpmBuckets.length === 0">
                                <td class="py-2 text-white/40" colspan="3">No trials yet.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- raw trial records -->
            <div class="mt-6 rounded-2xl border border-white/10 bg-white/5 p-5 shadow-2xl shadow-black/40">
                <h2 class="mb-3 text-lg font-semibold">All Trials</h2>
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-sm">
                        <thead>
                            <tr class="text-white/50">
                                <th
                                    v-for="col in sortableColumns"
                                    :key="col.key"
                                    class="cursor-pointer select-none whitespace-nowrap py-1 pr-6 hover:text-white"
                                    @click="setSort(col.key)"
                                >
                                    {{ col.label }}
                                    <span v-if="sortKey === col.key">{{ sortDir === 'asc' ? '▲' : '▼' }}</span>
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="row in sortedRows" :key="row.id" class="border-t border-white/10">
                                <td class="py-2 pr-6 whitespace-nowrap">{{ row.participantId }}</td>
                                <td class="py-2 pr-6 font-mono">{{ row.wpm }}</td>
                                <td class="py-2 pr-6">{{ row.passageId }}</td>
                                <td class="py-2 pr-6 font-mono">{{ row.trialOrderIndex }}</td>
                                <td class="py-2 pr-6 font-mono">{{ row.comprehensionPct.toFixed(0) }}% ({{ row.correctCount }}/{{ row.totalQuestions }})</td>
                                <td class="py-2 pr-6 font-mono">{{ row.actualDurationMs }}</td>
                                <td class="py-2 pr-6 font-mono">{{ row.expectedDurationMs }}</td>
                                <td class="py-2 pr-6">
                                    <span v-if="row.durationMismatchFlag" class="rounded-full bg-red/20 px-2 py-0.5 text-xs !text-red-light">flagged</span>
                                </td>
                                <td class="py-2 pr-6 font-mono">{{ row.quizDurationMs }}</td>
                                <td class="py-2 pr-6 whitespace-nowrap text-white/60">{{ row.timestampDate ? row.timestampDate.toLocaleString() : '—' }}</td>
                            </tr>
                            <tr v-if="sortedRows.length === 0">
                                <td class="py-2 text-white/40" colspan="10">No trials yet.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </template>
    </div>
</template>

<style scoped></style>
