// Standalone analytics script — NOT part of the deployed app, not imported
// by src/. Pulls every /lab session from Firestore, aggregates accuracy by
// condition x speed, and writes charts + a markdown summary to disk.
//
// Run with: node analytics/analytics.js   (from the app/ directory)
//
// Schema note: there is no top-level "trials" Firestore collection. Each
// completed /lab run is written as one document in the `labRuns` collection
// (see src/pages/LabPage.vue's finalizeRun), with a `trials` ARRAY field
// holding the individual trial records. This script fetches `labRuns` and
// flattens that array field into the per-trial rows it aggregates.
//
// The "condition" values requested (rsvp / time_capped_normal) don't exist
// verbatim in the data either — the app stores them as trial.mode: 'rsvp'
// or 'timed'. This script maps mode 'timed' -> label 'time_capped_normal'
// for display; see CONDITIONS below.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { ChartJSNodeCanvas } from 'chartjs-node-canvas';
import {
    BarController,
    BarElement,
    CategoryScale,
    LinearScale,
    Legend,
    Title,
    Tooltip
} from 'chart.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = path.join(__dirname, 'analytics_output');
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const RAW_OUTPUT_PATH = path.join(__dirname, 'raw_trials.json');
const SUMMARY_OUTPUT_PATH = path.join(__dirname, 'summary.md');

const LOW_SAMPLE_THRESHOLD = 5;
const EXPECTED_WPMS = [250, 450];
// dataviz skill's default categorical slots 1 (blue) and 2 (orange) —
// validated as CVD-safe adjacent pair, in fixed order.
const CONDITIONS = [
    { modeField: 'rsvp', label: 'rsvp', color: '#2a78d6' },
    { modeField: 'timed', label: 'time_capped_normal', color: '#eb6834' }
];

// ---------- 1. connect + pull ----------

function loadServiceAccount() {
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error(`\nMissing service account key: ${SERVICE_ACCOUNT_PATH}\n`);
        console.error('Generate one:');
        console.error('  1. https://console.firebase.google.com/project/fast-lit/settings/serviceaccounts/adminsdk');
        console.error('  2. Click "Generate new private key" (downloads a JSON file)');
        console.error(`  3. Save it as: ${SERVICE_ACCOUNT_PATH}`);
        console.error('     (already gitignored — never commit this file)\n');
        process.exit(1);
    }
    return JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8'));
}

async function fetchLabRuns() {
    const serviceAccount = loadServiceAccount();
    const app = initializeApp({ credential: cert(serviceAccount) });
    const db = getFirestore(app);
    const snapshot = await db.collection('labRuns').get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

// ---------- 2. aggregation ----------

function mean(values) {
    return values.reduce((sum, v) => sum + v, 0) / values.length;
}

// Sample standard deviation (n-1 denominator).
function stddev(values, avg) {
    if (values.length < 2) return 0;
    const variance = values.reduce((sum, v) => sum + (v - avg) ** 2, 0) / (values.length - 1);
    return Math.sqrt(variance);
}

function buildGroups(runs) {
    const groups = new Map();
    for (const cond of CONDITIONS) {
        for (const wpm of EXPECTED_WPMS) {
            groups.set(`${cond.modeField}_${wpm}`, {
                condition: cond.label,
                modeField: cond.modeField,
                wpm,
                color: cond.color,
                accuracies: []
            });
        }
    }

    let totalTrials = 0;
    const unrecognized = [];

    for (const run of runs) {
        const trials = Array.isArray(run.trials) ? run.trials : [];
        for (const trial of trials) {
            totalTrials++;
            const key = `${trial?.mode}_${trial?.wpm}`;
            const group = groups.get(key);
            const totalQuestions = trial?.quiz?.totalQuestions;
            const correctCount = trial?.quiz?.correctCount;
            const hasValidQuiz =
                typeof totalQuestions === 'number' && typeof correctCount === 'number' && totalQuestions > 0;

            if (!group || !hasValidQuiz) {
                unrecognized.push({ runId: run.id, mode: trial?.mode, wpm: trial?.wpm });
                continue;
            }
            group.accuracies.push((correctCount / totalQuestions) * 100);
        }
    }

    const results = [...groups.values()].map((g) => {
        const n = g.accuracies.length;
        const meanAccuracy = n ? mean(g.accuracies) : 0;
        const sd = n ? stddev(g.accuracies, meanAccuracy) : 0;
        const se = n ? sd / Math.sqrt(n) : 0;
        return { condition: g.condition, wpm: g.wpm, color: g.color, n, meanAccuracy, stddev: sd, se };
    });

    return { results, totalTrials, unrecognized };
}

// ---------- 3. charts ----------

// Draws a +/- SE whisker over each bar. Reads a parallel `errorBars` array
// off the dataset (same index as `data`); does nothing for datasets that
// don't set one (e.g. the sample-size chart).
const errorBarsPlugin = {
    id: 'errorBars',
    afterDatasetsDraw(chart) {
        const { ctx } = chart;
        chart.data.datasets.forEach((dataset, datasetIndex) => {
            if (!dataset.errorBars) return;
            const meta = chart.getDatasetMeta(datasetIndex);
            const yScale = chart.scales.y;
            meta.data.forEach((bar, index) => {
                const se = dataset.errorBars[index];
                if (!se) return;
                const value = dataset.data[index];
                const yTop = yScale.getPixelForValue(value + se);
                const yBottom = yScale.getPixelForValue(Math.max(0, value - se));
                const x = bar.x;
                const capWidth = 12;
                ctx.save();
                ctx.strokeStyle = '#0b0b0b';
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.moveTo(x, yTop);
                ctx.lineTo(x, yBottom);
                ctx.moveTo(x - capWidth / 2, yTop);
                ctx.lineTo(x + capWidth / 2, yTop);
                ctx.moveTo(x - capWidth / 2, yBottom);
                ctx.lineTo(x + capWidth / 2, yBottom);
                ctx.stroke();
                ctx.restore();
            });
        });
    }
};

// Selective direct label above each bar (the value itself, formatted per
// dataset via `labelFormatter`).
const valueLabelsPlugin = {
    id: 'valueLabels',
    afterDatasetsDraw(chart) {
        const { ctx } = chart;
        chart.data.datasets.forEach((dataset, datasetIndex) => {
            const meta = chart.getDatasetMeta(datasetIndex);
            meta.data.forEach((bar, index) => {
                const value = dataset.data[index];
                const label = dataset.labelFormatter ? dataset.labelFormatter(value) : String(value);
                const hasErrorBar = dataset.errorBars && dataset.errorBars[index];
                const offsetY = hasErrorBar ? 22 : 10;
                ctx.save();
                ctx.fillStyle = '#52514e';
                ctx.font = "600 15px system-ui, -apple-system, 'Segoe UI', sans-serif";
                ctx.textAlign = 'center';
                ctx.fillText(label, bar.x, bar.y - offsetY);
                ctx.restore();
            });
        });
    }
};

// Dashed reference line, enabled per-chart via options.plugins.thresholdLine.
const thresholdLinePlugin = {
    id: 'thresholdLine',
    afterDatasetsDraw(chart, _args, opts) {
        if (!opts || opts.value == null) return;
        const { ctx, chartArea, scales } = chart;
        const y = scales.y.getPixelForValue(opts.value);
        ctx.save();
        ctx.strokeStyle = '#fab219';
        ctx.setLineDash([6, 4]);
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(chartArea.left, y);
        ctx.lineTo(chartArea.right, y);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillStyle = '#52514e';
        ctx.font = "600 13px system-ui, -apple-system, 'Segoe UI', sans-serif";
        ctx.textAlign = 'left';
        ctx.fillText(opts.label ?? `threshold (${opts.value})`, chartArea.left + 8, y - 8);
        ctx.restore();
    }
};

const FONT_FAMILY = "system-ui, -apple-system, 'Segoe UI', sans-serif";
const INK = '#0b0b0b';
const INK_SECONDARY = '#52514e';
const INK_MUTED = '#898781';
const GRIDLINE = '#e1e0d9';

function baseOptions(titleText, yTitle) {
    return {
        responsive: false,
        layout: { padding: { top: 24, right: 24, bottom: 8, left: 8 } },
        plugins: {
            title: {
                display: true,
                text: titleText,
                color: INK,
                font: { size: 22, weight: '600', family: FONT_FAMILY },
                padding: { bottom: 20 }
            },
            legend: {
                position: 'top',
                align: 'end',
                labels: { color: INK_SECONDARY, usePointStyle: true, font: { size: 14, family: FONT_FAMILY } }
            },
            tooltip: { enabled: false }
        },
        scales: {
            x: {
                grid: { display: false },
                ticks: { color: INK_SECONDARY, font: { size: 14, family: FONT_FAMILY } },
                border: { color: GRIDLINE }
            },
            y: {
                beginAtZero: true,
                grace: '12%',
                grid: { color: GRIDLINE },
                border: { display: false },
                ticks: { color: INK_MUTED, font: { size: 13, family: FONT_FAMILY } },
                title: { display: true, text: yTitle, color: INK_SECONDARY, font: { size: 14, family: FONT_FAMILY } }
            }
        }
    };
}

function datasetFor(cond, values, extra = {}) {
    return {
        label: cond.label,
        data: values,
        backgroundColor: cond.color,
        borderRadius: { topLeft: 4, topRight: 4 },
        borderSkipped: false,
        barPercentage: 0.75,
        categoryPercentage: 0.7,
        ...extra
    };
}

async function generateCharts(results) {
    const canvasRenderer = new ChartJSNodeCanvas({
        width: 1600,
        height: 1000,
        backgroundColour: '#fcfcfb',
        chartCallback: (ChartJS) => {
            ChartJS.register(
                BarController,
                BarElement,
                CategoryScale,
                LinearScale,
                Legend,
                Title,
                Tooltip,
                errorBarsPlugin,
                valueLabelsPlugin,
                thresholdLinePlugin
            );
        }
    });

    const byWpm = EXPECTED_WPMS.map((wpm) => ({
        wpm,
        rsvp: results.find((r) => r.wpm === wpm && r.condition === 'rsvp'),
        timed: results.find((r) => r.wpm === wpm && r.condition === 'time_capped_normal')
    }));
    const labels = byWpm.map((w) => `${w.wpm} wpm`);
    const rsvpCond = CONDITIONS[0];
    const timedCond = CONDITIONS[1];

    // Chart 1: grouped mean accuracy % with +/- SE error bars.
    const accuracyOptions = baseOptions('Mean comprehension accuracy by speed and condition', 'Mean accuracy (%, ± SE)');
    accuracyOptions.scales.y.max = 100;
    const accuracyConfig = {
        type: 'bar',
        data: {
            labels,
            datasets: [
                datasetFor(
                    rsvpCond,
                    byWpm.map((w) => Number(w.rsvp.meanAccuracy.toFixed(1))),
                    { errorBars: byWpm.map((w) => w.rsvp.se), labelFormatter: (v) => `${v.toFixed(1)}%` }
                ),
                datasetFor(
                    timedCond,
                    byWpm.map((w) => Number(w.timed.meanAccuracy.toFixed(1))),
                    { errorBars: byWpm.map((w) => w.timed.se), labelFormatter: (v) => `${v.toFixed(1)}%` }
                )
            ]
        },
        options: accuracyOptions
    };

    // Chart 2: sample size per group, with a low-sample threshold line.
    const sampleSizeOptions = baseOptions('Sample size (n) by speed and condition', 'Trials collected (n)');
    sampleSizeOptions.plugins.thresholdLine = {
        value: LOW_SAMPLE_THRESHOLD,
        label: `low-sample threshold (n=${LOW_SAMPLE_THRESHOLD})`
    };
    const sampleSizeConfig = {
        type: 'bar',
        data: {
            labels,
            datasets: [
                datasetFor(
                    rsvpCond,
                    byWpm.map((w) => w.rsvp.n),
                    { labelFormatter: (v) => `${v}` }
                ),
                datasetFor(
                    timedCond,
                    byWpm.map((w) => w.timed.n),
                    { labelFormatter: (v) => `${v}` }
                )
            ]
        },
        options: sampleSizeOptions
    };

    fs.mkdirSync(OUTPUT_DIR, { recursive: true });

    const accuracyBuffer = await canvasRenderer.renderToBuffer(accuracyConfig);
    fs.writeFileSync(path.join(OUTPUT_DIR, 'accuracy_by_condition.png'), accuracyBuffer);

    const sampleSizeBuffer = await canvasRenderer.renderToBuffer(sampleSizeConfig);
    fs.writeFileSync(path.join(OUTPUT_DIR, 'sample_size_by_group.png'), sampleSizeBuffer);
}

// ---------- 4. summary output ----------

function buildSummary({ results, totalSessions, totalTrials, unrecognized }) {
    const header = '| condition | speed | n | mean accuracy % | std dev | SE |';
    const divider = '|---|---|---|---|---|---|';
    const rows = results.map(
        (r) => `| ${r.condition} | ${r.wpm} | ${r.n} | ${r.meanAccuracy.toFixed(1)} | ${r.stddev.toFixed(1)} | ${r.se.toFixed(1)} |`
    );
    const table = [header, divider, ...rows].join('\n');

    const lowSample = results.filter((r) => r.n < LOW_SAMPLE_THRESHOLD);

    let md = `# Lab trial analytics\n\nGenerated ${new Date().toISOString()}\n\n`;
    md += `## Results by condition x speed\n\n${table}\n\n`;
    md += `## Overall totals\n\n- Total sessions completed: ${totalSessions}\n- Total trials collected: ${totalTrials}\n`;

    md += `\n## Low sample warning\n\n`;
    md +=
        lowSample.length === 0
            ? 'None — every group has n >= ' + LOW_SAMPLE_THRESHOLD + '.\n'
            : lowSample.map((g) => `- **${g.condition} @ ${g.wpm} wpm** — n = ${g.n} — low sample warning\n`).join('');

    if (unrecognized.length) {
        md += `\n## Schema warning\n\n${unrecognized.length} trial record(s) did not match the expected shape `;
        md += '(mode in {rsvp, timed}, wpm in {250, 450}, quiz.correctCount/quiz.totalQuestions present) ';
        md += 'and were excluded from aggregation. Examples:\n\n';
        for (const u of unrecognized.slice(0, 10)) {
            md += `- runId \`${u.runId}\`: mode=${JSON.stringify(u.mode)}, wpm=${JSON.stringify(u.wpm)}\n`;
        }
    }

    return { md, table };
}

// ---------- main ----------

async function main() {
    console.log('Fetching labRuns from Firestore (project: fast-lit)...');
    const runs = await fetchLabRuns();
    console.log(`Fetched ${runs.length} labRuns document(s).`);

    fs.writeFileSync(RAW_OUTPUT_PATH, JSON.stringify(runs, null, 2));
    console.log(`Raw data saved to ${RAW_OUTPUT_PATH}`);

    if (runs.length === 0) {
        console.warn('\nNo documents found in labRuns — nothing to aggregate. Check the collection name/project.');
    } else {
        console.log('\nSample document (first result, trials truncated to 1 for readability):');
        console.log(
            JSON.stringify(
                { id: runs[0].id, trialCount: runs[0].trials?.length ?? 0, firstTrial: runs[0].trials?.[0] ?? null },
                null,
                2
            )
        );
    }

    const { results, totalTrials, unrecognized } = buildGroups(runs);

    if (unrecognized.length) {
        console.warn(
            `\nWARNING: ${unrecognized.length} trial record(s) did not match the expected schema ` +
                '(mode in {rsvp, timed}, wpm in {250, 450}, quiz.correctCount/quiz.totalQuestions present) ' +
                'and were excluded. First few:'
        );
        console.warn(unrecognized.slice(0, 5));
    }

    await generateCharts(results);
    console.log(`Charts saved to ${OUTPUT_DIR}/`);

    const { md, table } = buildSummary({ results, totalSessions: runs.length, totalTrials, unrecognized });
    fs.writeFileSync(SUMMARY_OUTPUT_PATH, md);

    console.log('\n' + table + '\n');
    console.log(`Total sessions completed: ${runs.length}`);
    console.log(`Total trials collected: ${totalTrials}`);

    const lowSample = results.filter((r) => r.n < LOW_SAMPLE_THRESHOLD);
    if (lowSample.length) {
        console.log('\nLow sample warning:');
        for (const g of lowSample) console.log(`  - ${g.condition} @ ${g.wpm} wpm: n = ${g.n}`);
    }

    console.log(`\nFull summary written to ${SUMMARY_OUTPUT_PATH}`);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error('Analytics run failed:', err);
        process.exit(1);
    });
