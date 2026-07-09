<script setup>
import Header from '../components/Header.vue';
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue';
import { WriteScripts } from '@/assets/textScripts.js';
import { db } from '@/firebase/index.js';
import { collection, getDocs, doc, updateDoc, increment } from "firebase/firestore";

const canvas = ref(null);

const colorCanvasBackground = '#120A3D';              // matches main page background
const colorCellOff = '#1A124D';                       // slightly lighter for grid off-cells
const colorCellOn = '#F3EFFE';                        // very light for on-cells; warm off-white
const colorWritingLineOff = '#38297A';                // dark purple for sub-lines/guide lines

const gridGap = 0.01;               // gap between cells, as a fraction of the canvas size
const innerCornerRadius = 0.4;      // corner rounding for non-edge cells, as a fraction of the gap
const dimension = 20;                // grid is dimension x dimension cells
const writingLineDivisions = 4;      // N: writing line sits (N-1)/N of the way down the grid
const writingLineFraction = (writingLineDivisions - 1) / writingLineDivisions;
const writingLineRow = Math.round(writingLineFraction * dimension);
const grid = ref(Array.from({ length: dimension }, () => Array(dimension).fill(0)));

// Converts the canvas's on-screen pixel size into the measurements needed to
// place cells: how big each cell is, how much space separates them, and how
// far the grid is inset from the canvas edge.
function getGridLayout(size) {
    const gap = size * gridGap;
    const padding = gap;
    const available = size - 2 * padding - (dimension - 1) * gap;
    const cellSize = available / dimension;
    return { gap, padding, cellSize };
}

// Finds the closest cell index along one axis for a given pixel offset,
// clamped to stay within the grid, so clicks near the edges/gaps still land
// on a cell instead of missing.
function getNearestCellIndex(local, pitch, cellSize) {
    const index = Math.round((local - cellSize / 2) / pitch);
    return Math.min(dimension - 1, Math.max(0, index));
}

// Maps a click point in canvas-local pixel coordinates to the {row, col} of
// the nearest grid cell.
function getCellsFromPoint(x, y, layout) {
    const { padding, cellSize } = layout;
    const pitch = cellSize + layout.gap;

    const localX = x - padding;
    const localY = y - padding;

    const col = getNearestCellIndex(localX, pitch, cellSize);
    const row = getNearestCellIndex(localY, pitch, cellSize);

    return [{ row, col }];
}

// Corner radii can't exceed half a cell's size, or the rounded rect would
// self-intersect and render incorrectly.
function clampRadius(radius, cellSize) {
    return Math.min(radius, cellSize / 2);
}

// Returns the four corner radii (in roundRect's [top-left, top-right,
// bottom-right, bottom-left] order) for a single cell.
function getCellCornerRadii(row, col, gap, cellSize, canvasCornerRadius) {
    const inner = clampRadius(gap * innerCornerRadius, cellSize);
    const corner = clampRadius(canvasCornerRadius, cellSize);

    // Only the outward-facing corner on each grid corner cell is boosted.
    // [top-left, top-right, bottom-right, bottom-left]
    return [
        row === 0 && col === 0 ? corner : inner,
        row === 0 && col === dimension - 1 ? corner : inner,
        row === dimension - 1 && col === dimension - 1 ? corner : inner,
        row === dimension - 1 && col === 0 ? corner : inner,
    ];
}

// Renders a dimension x dimension 0/1 grid from scratch onto a given canvas
// element — there's no incremental redraw, the canvas is cleared and every
// cell is repainted each time. Shared by the main writing canvas (drawGrid,
// below) and the grid-view mini previews in the show-data modal, so both
// stay visually consistent (including the writing-line guide row) without
// duplicating the drawing logic.
function drawGridOnCanvas(el, gridData) {
    if (!el) return;

    const ctx = el.getContext('2d');

    // The canvas element has a CSS size (rect.width/height, in CSS pixels)
    // but its drawing buffer is a separate pixel grid. On high-DPI screens
    // (dpr > 1) we size that buffer up and scale the context to match, so
    // shapes are drawn at native resolution instead of looking blurry.
    const dpr = window.devicePixelRatio || 1;
    const rect = el.getBoundingClientRect();
    const size = rect.width; // canvas is styled aspect-square, so width == height

    el.width = size * dpr;
    el.height = size * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    // Layout math (cell size/gap/padding) is derived once per draw from the
    // current on-screen size, since the canvas can resize with the viewport.
    const { gap, padding, cellSize } = getGridLayout(size);
    // Reuse the canvas's own CSS border radius so the grid's outer corners
    // visually match the rounded canvas container.
    const canvasCornerRadius = parseFloat(getComputedStyle(el).borderTopLeftRadius) || 16;

    // Paint the background first; this also fills the thin gaps between
    // cells, since cells are drawn smaller than their (cellSize + gap) pitch.
    ctx.fillStyle = colorCanvasBackground;
    ctx.fillRect(0, 0, size, size);

    for (let row = 0; row < dimension; row++) {
        for (let col = 0; col < dimension; col++) {
            // Each cell's top-left corner sits one (cellSize + gap) "pitch"
            // step from the previous one, offset by the outer padding.
            const x = padding + col * (cellSize + gap);
            const y = padding + row * (cellSize + gap);

            // Color priority: lit cells are always colorCellOn. Otherwise,
            // cells on the writing-line row get a lighter "off" shade so the
            // line is visible even where nothing has been drawn.
            const isOn = gridData[row][col] === 1;
            const isWritingLine = row === writingLineRow;
            ctx.fillStyle = isOn ? colorCellOn : isWritingLine ? colorWritingLineOff : colorCellOff;

            // Corners are rounded per-cell (with special-cased larger radii
            // on the grid's four outer corners) rather than clipping the
            // whole canvas, so each cell reads as a distinct rounded square.
            ctx.beginPath();
            ctx.roundRect(
                x,
                y,
                cellSize,
                cellSize,
                getCellCornerRadii(row, col, gap, cellSize, canvasCornerRadius),
            );
            ctx.fill();
        }
    }
}

// Renders the shared reactive `grid` (the writing canvas the user draws on)
// onto the main canvas. Called on mount and whenever `grid` changes (see the
// `watch` below).
function drawGrid() {
    drawGridOnCanvas(canvas.value, grid.value);
}

// Renders one character's saved (static, non-reactive) grid onto its mini
// preview canvas in the show-data modal's grid view. Used as a :ref callback
// so each canvas draws itself as soon as it's mounted — v-if/v-for only keep
// these canvases in the DOM while the modal is open and grid view is active.
// The actual draw is deferred with nextTick: the ref callback fires
// synchronously mid-patch, before the browser has settled layout for the
// newly inserted canvas (particularly since the modal-box is sized with
// width:fit-content around this very content), so measuring the canvas's
// size immediately can read 0 and bake that into the canvas permanently.
function drawCharacterCanvas(el, char) {
    if (!el) return;
    nextTick(() => drawGridOnCanvas(el, char.grid));
}

// Lights up the cell (or nearest cell) at a given canvas-local point.
function handleCanvasClick(x, y) {
    const el = canvas.value;
    if (!el) return;

    const layout = getGridLayout(el.getBoundingClientRect().width);
    const cells = getCellsFromPoint(x, y, layout);

    for (const { row, col } of cells) {
        grid.value[row][col] = 1;
    }
}

// Tracks whether the pointer is currently held down, so drag movement is
// only treated as drawing between a pointerdown and the matching pointerup.
let isDrawing = false;

// Converts a pointer event's page coordinates into canvas-local coordinates,
// returning null if the point falls outside the canvas.
function getCanvasPoint(event) {
    const el = canvas.value;
    if (!el) return null;

    const rect = el.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;

    if (x < 0 || x > rect.width || y < 0 || y > rect.height) {
        return null;
    }

    return { x, y };
}

// Pointer events (rather than mouse-only events) so this works for both
// mouse and touch input.
function onPointerDown(event) {
    isDrawing = true;

    const point = getCanvasPoint(event);
    if (point) {
        handleCanvasClick(point.x, point.y);
    }
}

// Listens on window (not just the canvas) so dragging keeps drawing even if
// the pointer briefly leaves the canvas bounds mid-drag.
function onPointerMove(event) {
    if (!isDrawing) return;

    const point = getCanvasPoint(event);
    if (point) {
        handleCanvasClick(point.x, point.y);
    }
}

// Releasing the pointer ends the current drag and clears the grid. Guarded
// on isDrawing (only set true by a pointerdown on the canvas itself) since
// this listener is on window to keep dragging past the canvas edge working —
// without the guard, releasing the mouse anywhere on the page would reset
// the grid and register a character even if the drag never touched the canvas.
function onPointerUp() {
    if (!isDrawing) return;
    isDrawing = false;
    resetGrid();
}

// Redraw any time the grid data changes.
watch(grid, drawGrid, { deep: true });

function resetGrid() {
    recognizeCharacter();
    if (!grid.value || !Array.isArray(grid.value)) return;
    for (let row = 0; row < grid.value.length; row++) {
        for (let col = 0; col < grid.value[row].length; col++) {
            grid.value[row][col] = 0;
        }
    }
}

// character recognition

const writeChars = ref([]);

// Counts every character recognized in Write mode during this session,
// converted to an approximate word count (5 letters average per word) and
// flushed to Firestore's totalWordsWritten field — the same field
// HomePage.vue reads for the Words Written stat and its hours-saved bonus.
let charactersInSession = 0;

function recognizeCharacter() {
    charactersInSession++;
    if (currentPage.value == Pages.WRITE) {
        // Push a random lowercase alphabet character
        const randomChar = String.fromCharCode(97 + Math.floor(Math.random() * 26));
        writeChars.value.push(randomChar);
    }
    else if (currentPage.value == Pages.LEARN) {
    }
    else if (currentPage.value == Pages.DEVELOPER) {
        if (currentLabel.value.length != 0) {
            // Deep copy the grid before pushing
            const gridCopy = JSON.parse(JSON.stringify(grid.value));
            data.value.push(
                new Character(
                    crypto.randomUUID(),
                    currentLabel.value,
                    gridCopy
                )
            );
        }
    }
}

// stats — totalWordsWritten in firestore

let statsDocId;

onMounted(async () => {
    const querySnapshot = await getDocs(collection(db, "stats"));
    querySnapshot.forEach((doc) => {
        statsDocId = doc.id;
    });
});

// same increment-on-close pattern as HomePage.vue's saveDemoWordsRead and
// Reader.vue's updateTotalWordsRead, added to the firestore total when the
// page is closed, reloaded, or navigated away from within the app.
async function updateTotalWordsWritten() {
    if (charactersInSession > 0 && statsDocId) {
        const statsRef = doc(db, "stats", statsDocId);
        await updateDoc(statsRef, {
            totalWordsWritten: increment(charactersInSession / 5)
        });
        charactersInSession = 0;
    }
}

window.addEventListener('beforeunload', updateTotalWordsWritten);

// lifecycle hooks

onMounted(() => {
    canvas.value = document.getElementById('drawCanvas');
    drawGrid();
    canvas.value.addEventListener('pointerdown', onPointerDown);
    window.addEventListener('pointermove', onPointerMove);
    window.addEventListener('pointerup', onPointerUp);
});

onUnmounted(() => {
    canvas.value?.removeEventListener('pointerdown', onPointerDown);
    window.removeEventListener('pointermove', onPointerMove);
    window.removeEventListener('pointerup', onPointerUp);

    // beforeunload only fires on an actual tab close/reload — navigating to
    // another page within the app just unmounts this component, so flush
    // the count here too, and drop the listener since it'd otherwise stack
    // up (and misfire with a stale statsDocId) if the user revisits the
    // write page.
    window.removeEventListener('beforeunload', updateTotalWordsWritten);
    updateTotalWordsWritten();
});

// pages
const Pages = Object.freeze({
    WRITE: "write",
    LEARN: "learn",
    DEVELOPER: "developer"
});
const currentPage = ref(Pages.WRITE);

// handles opening and closing of the data accordion
const isDataOpen = ref(false);

// handles toggle between code view and grid view
const isCodeView = ref(true);

// handles opening and closing of the view json modal
const isViewJsonModalOpen = ref(false);

// developer page

const currentLabel = ref("");

class Character {
    constructor(id, label, grid) {
        this.id = id;
        this.label = label;
        this.grid = grid;
    }
}

const data = ref([]);
const renderableData = ref({});

// 4 space indent for rendering code
const indent = "    ";

// Persists `data` to IndexedDB so saved characters survive a reload.
// Vue's reactive arrays/objects are Proxies, which IndexedDB's
// structured-clone algorithm can't serialize directly (it throws
// DataCloneError trying to store one), so records are stringified before
// being put in the store and parsed back on load rather than storing
// `data.value` as-is.
const WRITE_DB_NAME = "fastlit-write";
const WRITE_DB_VERSION = 1;
const WRITE_DB_STORE = "characters";
const WRITE_DB_KEY = "data";

function openWriteDb() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(WRITE_DB_NAME, WRITE_DB_VERSION);
        request.onupgradeneeded = () => {
            request.result.createObjectStore(WRITE_DB_STORE);
        };
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

async function loadDataFromDb() {
    try {
        const db = await openWriteDb();
        const stored = await new Promise((resolve, reject) => {
            const tx = db.transaction(WRITE_DB_STORE, "readonly");
            const request = tx.objectStore(WRITE_DB_STORE).get(WRITE_DB_KEY);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
        return stored ? JSON.parse(stored) : [];
    } catch {
        // IndexedDB unavailable (e.g. private browsing) — fall back to an
        // empty, in-session-only data set.
        return [];
    }
}

async function saveDataToDb(value) {
    try {
        const db = await openWriteDb();
        await new Promise((resolve, reject) => {
            const tx = db.transaction(WRITE_DB_STORE, "readwrite");
            tx.objectStore(WRITE_DB_STORE).put(JSON.stringify(value), WRITE_DB_KEY);
            tx.oncomplete = () => resolve();
            tx.onerror = () => reject(tx.error);
        });
    } catch {
        // data still works for this session, it just won't persist.
    }
}

// restore any previously saved characters once on mount
onMounted(async () => {
    data.value = await loadDataFromDb();
});

// watch data's value so that we can create renderableData
// so that data can more easily be parsed and displayed in the html
watch(data, (newData) => {
    saveDataToDb(newData);

    // reset renderableData, it will be reconstructed later in this method
    renderableData.value = {};
    newData.forEach((char) => {
        if (!Object.hasOwn(renderableData.value, char.label)) {
            // create a new subcategory in renderableData for the label
            renderableData.value[char.label] = [];
        }
        // add the character into the category of its label
        renderableData.value[char.label].push(char);
    });
}, { deep: true });

function exportJson() {
    const json = JSON.stringify(data.value, null, 4);

    const blob = new Blob([json], {
        type: "application/json"
    });

    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = "fast_list_write_export.json";
    a.click();

    URL.revokeObjectURL(url);
}

// Removes a single saved character by id. data is the source of truth —
// renderableData rebuilds automatically via the watch above once data changes.
function deleteCharacter(id) {
    data.value = data.value.filter((char) => char.id !== id);
}

// very simple at-a-glance stats for the developer panel
const uniqueLabelCount = computed(() => Object.keys(renderableData.value).length);
const mostCommonLabel = computed(() => {
    const entries = Object.entries(renderableData.value);
    if (entries.length === 0) return null;
    return entries.reduce((max, entry) => entry[1].length > max[1].length ? entry : max);
});

// Wipes every saved character. Goes through the same `data` source of
// truth as deleteCharacter, so renderableData and IndexedDB both stay
// in sync automatically via the watch above.
function clearAllData() {
    if (data.value.length === 0) return;
    if (!confirm("Clear all saved characters? This can't be undone.")) return;
    data.value = [];
    currentLabel.value = "";
}
</script>

<template>
    <Header pageName="Write" />

    <!-- main page content, wide enough for the split-screen layout below -->
    <div class="mx-auto max-w-4xl p-5">
        <!-- page tabs, styled as a dark segmented control to match the rest of the site -->
        <div class="mb-6 inline-flex gap-1 rounded-2xl border border-white/10 bg-white/5 p-1 w-full">
            <button
                v-for="page in Object.values(Pages)"
                :key="page"
                class="rounded-xl px-5 py-2 text-sm font-semibold capitalize transition-colors duration-150 focus-ring w-full cursor-pointer"
                :class="currentPage === page ? 'bg-red text-white' : 'text-white/60 hover:bg-white/10 hover:text-white'"
                @click="currentPage = page"
            >{{ page }}</button>
        </div>

        <!-- split screen: the write box (canvas) stays fixed on the left,
             the active tab's panel fills the remaining space on the right.
             Stacks vertically (canvas on top) on small screens.
             items-start (not items-stretch) is deliberate: flex's stretch
             sizing can interact unpredictably with the canvas's aspect-square
             sizing depending on the right panel's content height, visibly
             elongating the canvas beyond its intended size. Instead the
             right panel gets an explicit lg:h-[...] using the exact same
             min(90vw,65vh,29rem) formula as the canvas, so both are sized
             independently off the same fixed expression — no cross-axis
             interaction, and the grid stays the same size no matter which
             tab (or how much content) is on the right. -->
        <div class="flex flex-col items-start gap-6 lg:flex-row">
            <canvas
                id="drawCanvas"
                class="
                    mx-auto
                    aspect-square
                    w-[min(90vw,65vh,29rem)]
                    shrink-0
                    touch-none
                    rounded-2xl
                    border
                    border-white/10
                    shadow-2xl
                    shadow-black/40
                    lg:mx-0
                    cursor-pointer
                "
            ></canvas>

            <div class="w-full min-w-0 lg:h-[min(90vw,65vh,29rem)]">
                <!-- write page -->
                <div
                    v-if="currentPage == Pages.WRITE"
                    class="flex h-full min-h-16 flex-wrap items-center justify-center gap-2 overflow-y-auto rounded-2xl border border-white/10 bg-white/5 p-4"
                >
                    <kbd
                        class="kbd kbd-xl rounded-lg bg-white text-gray-800 border border-gray-300 shadow"
                        v-for="(char, idx) in writeChars"
                        :key="idx"
                    >{{ char }}</kbd>
                </div>

                <!-- learn page -->
                <div
                    v-if="currentPage == Pages.LEARN"
                    class="flex h-full min-h-16 flex-wrap items-center justify-center gap-2 overflow-y-auto rounded-2xl border border-white/10 bg-white/5 p-4"
                >
                    <p class="text-white/70">learn page</p>
                </div>

                <!-- developer page — h-full fills the wrapper's fixed
                     lg:h-[...] height (matching the canvas independently,
                     see the comment above), with the stats card below
                     absorbing the leftover space via flex-1. overflow-y-auto
                     is a safety net in case content ever needs more room
                     than that fixed height provides, so it scrolls instead
                     of pushing the canvas taller. -->
                <div
                    v-if="currentPage == Pages.DEVELOPER"
                    class="flex h-full flex-col gap-4 overflow-y-auto rounded-2xl border border-white/10 bg-white/5 p-5"
                >
                    <!-- current label: the single field that decides what
                         every subsequent stroke gets classified as, so it
                         gets outsized visual weight relative to everything
                         else in this panel instead of reading as just
                         another input field -->
                    <div class="rounded-2xl border border-red/30 bg-red/5 p-5">
                        <div class="mb-2 flex items-center justify-between gap-2">
                            <label class="text-xs font-semibold uppercase tracking-widest text-red-light">
                                Label
                            </label>
                            <span
                                v-if="renderableData[currentLabel]?.length"
                                class="text-xs text-white/40"
                            >{{ renderableData[currentLabel].length }} saved for "{{ currentLabel }}"</span>
                        </div>
                        <input
                            class="input w-full !border-none !bg-transparent !px-0 !text-3xl !font-bold !text-white !shadow-none placeholder:!text-lg placeholder:!font-normal placeholder:!text-white/30 focus-ring"
                            v-model="currentLabel"
                            :placeholder="WriteScripts.devCharInputPlaceholder"
                        >
                    </div>

                    <!-- export data -->
                    <div class="flex flex-wrap gap-2 w-full">
                        <button
                            class="btn-red flex-1 min-w-[9rem]"
                            @click="isViewJsonModalOpen = true"
                            :disabled="data.length == 0"
                        >{{ WriteScripts.viewJsonButton }}</button>
                        <button
                            class="btn rounded-2xl border border-white/20 bg-white/5 text-white transition-colors hover:bg-white/10 focus-ring flex-1 min-w-[9rem] disabled:opacity-50 disabled:hover:bg-white/5"
                            @click="exportJson"
                            :disabled="data.length == 0"
                        >{{ WriteScripts.downloadJsonButton }}</button>
                    </div>
      

                    <!-- trigger for the show-data modal below -->
                    <button
                        class="btn rounded-2xl border border-white/20 bg-white/5 text-white transition-colors hover:bg-white/10 focus-ring"
                        @click="isDataOpen = true"
                    >{{ WriteScripts.accordionHeaderClosed }} ({{ data.length }})</button>

                    <!-- very simple stats — fills whatever vertical space is
                         left over once the panel is stretched to the canvas's
                         height, instead of leaving it blank -->
                    <div class="flex flex-1 flex-col justify-center gap-4 rounded-2xl border border-white/10 bg-white/5 p-5">
                        <p class="text-center text-xs font-semibold uppercase tracking-widest text-white/50">Stats</p>
                        <div class="grid grid-cols-3 gap-3 text-center">
                            <div>
                                <p class="text-3xl font-bold text-red-light">{{ data.length }}</p>
                                <p class="mt-1 text-xs text-white/50">Characters</p>
                            </div>
                            <div>
                                <p class="text-3xl font-bold text-red-light">{{ uniqueLabelCount }}</p>
                                <p class="mt-1 text-xs text-white/50">Labels</p>
                            </div>
                            <div>
                                <p class="text-3xl font-bold text-red-light">{{ mostCommonLabel ? mostCommonLabel[1].length : 0 }}</p>
                                <p class="mt-1 truncate text-xs text-white/50">{{ mostCommonLabel ? `"${mostCommonLabel[0]}"` : "Most Common" }}</p>
                            </div>
                        </div>
                    </div>

                    <!-- clear all -->
                    <button
                        class="btn w-full rounded-2xl border border-red/40 bg-transparent text-red-light transition-colors hover:bg-red/10 focus-ring disabled:opacity-50 disabled:hover:bg-transparent"
                        :disabled="data.length == 0"
                        @click="clearAllData"
                    >Clear All Data</button>
                </div>
            </div>
        </div>
    </div>

    <!-- view json modal -->
    <dialog
        class="modal"
        :class="{ 'modal-open': isViewJsonModalOpen }"
    >
        <div class="modal-box bg-deepblue !w-fit !max-w-[95vw] h-7/8 flex flex-col overflow-hidden rounded-3xl border border-white/10 shadow-2xl shadow-black/40">
            <!-- header: close button + title share one relative row, same
                 structural pattern as the read page's settings modal -->
            <div class="relative flex items-center justify-center border-b border-white/10 pb-4">
                <button
                    class="btn btn-circle btn-ghost absolute left-0 top-1/2 -translate-y-1/2 transition-colors hover:bg-white/10 focus-ring"
                    @click="isViewJsonModalOpen = false"
                >
                    <svg
                        version="1.1"
                        id="Layer_1"
                        xmlns="http://www.w3.org/2000/svg"
                        xmlns:xlink="http://www.w3.org/1999/xlink"
                        x="0px"
                        y="0px"
                        width="16px"
                        height="16px"
                        viewBox="0 0 122.878 122.88"
                        fill="white"
                    >
                        <g>
                            <path
                                d="M1.426,8.313c-1.901-1.901-1.901-4.984,0-6.886c1.901-1.902,4.984-1.902,6.886,0
                                l53.127,53.127l53.127-53.127c1.901-1.902,4.984-1.902,6.887,0c1.901,1.901,1.901,4.985,0,6.886L68.324,61.439
                                l53.128,53.128c1.901,1.901,1.901,4.984,0,6.886c-1.902,1.902-4.985,1.902-6.887,0L61.438,68.326L8.312,121.453
                                c-1.901,1.902-4.984,1.902-6.886,0c-1.901-1.901-1.901-4.984,0-6.886l53.127-53.128L1.426,8.313L1.426,8.313z"
                            />
                        </g>
                    </svg>
                </button>

                <span class="text-2xl font-bold !text-red">{{ WriteScripts.viewJsonButton }}</span>
            </div>

            <!-- scrollable code area -->
            <div class="mt-6 flex-1 overflow-auto rounded-2xl">
                <!-- mockup-code's built-in per-line padding-right (1.25rem) reads as
                     much thinner than the left side's line-number gutter, so this adds
                     extra right padding on the container itself to balance them out. -->
                <div class="mockup-code w-full pe-10">
                    <!-- Very basic syntax highlighting: punctuation/brackets are dimmed
                        (text-white/40), JSON keys use the brand red-light accent, string
                        values are full white, and grid numbers use a soft violet — same
                        three-tone treatment as the accordion's code view below. -->

                    <!-- 1: Opening [ of the array -->
                    <pre data-prefix="1"><code><span class="text-white/40">[</span></code></pre>

                    <!-- For each character (object) in the data array -->
                    <div v-for="(char, idx1) in data">
                        <!-- 2 + (idx1 * 26): Opening { of the object; each character starts on a unique base for its block,
                        spaced by 26 lines to leave room for its grid rows -->
                        <pre
                            :data-prefix="2 + (idx1 * 26)"
                        ><code><span class="text-white/40">{{ indent }}{{ "{" }}</span></code></pre>

                        <!-- 3 + (idx1 * 26): "id" field line -->
                        <pre
                            :data-prefix="3 + (idx1 * 26)"
                        ><code><span class="text-white/40">{{ indent + indent }}</span><span class="text-red-light">"id"</span><span class="text-white/40">: </span><span class="text-white">"{{ char["id"] }}"</span><span class="text-white/40">,</span></code></pre>

                        <!-- 4 + (idx1 * 26): "label" field line -->
                        <pre
                            :data-prefix="4 + (idx1 * 26)"
                        ><code><span class="text-white/40">{{ indent + indent }}</span><span class="text-red-light">"label"</span><span class="text-white/40">: </span><span class="text-white">"{{ char["label"] }}"</span><span class="text-white/40">,</span></code></pre>

                        <!-- 5 + (idx1 * 26): "grid": [ line, starting of grid array -->
                        <pre
                            :data-prefix="5 + (idx1 * 26)"
                        ><code><span class="text-white/40">{{ indent + indent }}</span><span class="text-red-light">"grid"</span><span class="text-white/40">: [</span></code></pre>

                        <!-- 6 + (idx1 * 26) + idx2: Each row of the grid, where idx2 is the row index. -->
                        <!-- This ensures grid lines are numbered sequentially, starting right after the object metadata -->
                        <pre
                            v-for="(row, idx2) in char['grid']"
                            :data-prefix="6 + (idx1 * 26) + idx2"
                        ><code><span class="text-white/40">{{ indent + indent + indent }}[ </span><template v-for="(cell, i) in row" :key="i"><span :class="cell === 1 ? 'text-red-light' : 'text-violet-300'">{{ cell }}</span><span v-if="i < row.length - 1" class="text-white">,</span></template><span class="text-white/40"> ]{{ idx2 + 1 != dimension ? "," : "" }}</span></code></pre>

                        <!-- 26 + (idx1 * 26): Closing ] for the grid array, at a fixed offset regardless of grid length
                        (assumes grid is up to 20 rows, fills lines accordingly) -->
                        <pre
                            :data-prefix="26 + (idx1 * 26)"
                        ><code><span class="text-white/40">{{ indent + indent }}]</span></code></pre>

                        <!-- 27 + (idx1 * 26): Closing } for the object -->
                        <pre
                            :data-prefix="27 + (idx1 * 26)"
                        ><code><span class="text-white/40">{{ indent + "}" + (idx1 != data.length - 1 ? "," : "") }}</span></code></pre>
                    </div>

                    <!-- 28 + ((data.length - 1) * 26): Closing ] for the array.
                    This appears AFTER all objects, using the same offset math as above to place it after the last character's block.
                    -->
                    <pre
                        :data-prefix="28 + ((data.length - 1) * 26)"
                    ><code><span class="text-white/40">]</span></code></pre>
                </div>
            </div>
        </div>
    </dialog>

    <!-- show data modal — same header/close-icon pattern as the view json
         modal above. max-h (not a fixed height) plus a min-w lets the box
         size itself to content in both directions, so the empty-state
         walkthrough below doesn't end up in a tall, awkwardly narrow sliver. -->
    <dialog
        class="modal"
        :class="{ 'modal-open': isDataOpen }"
    >
        <div class="modal-box bg-deepblue !w-fit !max-w-[95vw] max-h-[85vh] min-w-[22rem] flex flex-col overflow-hidden rounded-3xl border border-white/10 shadow-2xl shadow-black/40">
            <div class="relative flex items-center justify-center border-b border-white/10 pb-4">
                <button
                    class="btn btn-circle btn-ghost absolute left-0 top-1/2 -translate-y-1/2 transition-colors hover:bg-white/10 focus-ring"
                    @click="isDataOpen = false"
                >
                    <svg
                        version="1.1"
                        id="Layer_1"
                        xmlns="http://www.w3.org/2000/svg"
                        xmlns:xlink="http://www.w3.org/1999/xlink"
                        x="0px"
                        y="0px"
                        width="16px"
                        height="16px"
                        viewBox="0 0 122.878 122.88"
                        fill="white"
                    >
                        <g>
                            <path
                                d="M1.426,8.313c-1.901-1.901-1.901-4.984,0-6.886c1.901-1.902,4.984-1.902,6.886,0
                                l53.127,53.127l53.127-53.127c1.901-1.902,4.984-1.902,6.887,0c1.901,1.901,1.901,4.985,0,6.886L68.324,61.439
                                l53.128,53.128c1.901,1.901,1.901,4.984,0,6.886c-1.902,1.902-4.985,1.902-6.887,0L61.438,68.326L8.312,121.453
                                c-1.901,1.902-4.984,1.902-6.886,0c-1.901-1.901-1.901-4.984,0-6.886l53.127-53.128L1.426,8.313L1.426,8.313z"
                            />
                        </g>
                    </svg>
                </button>

                <span class="text-2xl font-bold !text-red">{{ WriteScripts.accordionHeaderClosed }} ({{ data.length }})</span>
            </div>

            <!-- empty state: a short walkthrough instead of a blank list -->
            <div
                v-if="data.length === 0"
                class="flex flex-1 flex-col items-center justify-center gap-6 py-8"
            >
                <p class="text-white/60">{{ WriteScripts.noDataDescription }}</p>
                <div class="grid gap-4 sm:grid-cols-3">
                    <div
                        v-for="(step, idx) in WriteScripts.noDataSteps"
                        :key="step.title"
                        class="w-56 rounded-2xl border border-white/10 bg-white/5 p-5 text-left"
                    >
                        <span class="mb-3 flex h-8 w-8 items-center justify-center rounded-full bg-red text-sm font-bold">
                            {{ idx + 1 }}
                        </span>
                        <h3 class="mb-1 font-semibold">{{ step.title }}</h3>
                        <p class="text-sm text-white/70">{{ step.description }}</p>
                    </div>
                </div>
            </div>

            <template v-else>
                <!-- Grid/Code toggle, styled as the same segmented pill
                     control used for the Write/Learn/Developer tabs -->
                <div class="mt-4 inline-flex gap-1 self-center rounded-2xl border border-white/10 bg-white/5 p-1">
                    <button
                        class="rounded-xl px-5 py-2 text-sm font-semibold transition-colors duration-150 focus-ring"
                        :class="!isCodeView ? 'bg-red text-white' : 'text-white/60 hover:bg-white/10 hover:text-white'"
                        @click="isCodeView = false"
                    >Grid</button>
                    <button
                        class="rounded-xl px-5 py-2 text-sm font-semibold transition-colors duration-150 focus-ring"
                        :class="isCodeView ? 'bg-red text-white' : 'text-white/60 hover:bg-white/10 hover:text-white'"
                        @click="isCodeView = true"
                    >Code</button>
                </div>

                <!-- scrollable data area -->
                <div class="mt-6 flex-1 overflow-auto rounded-2xl text-sm">
                    <div
                        v-for="label in Object.keys(renderableData)"
                        :key="label"
                        class="mb-4 rounded-2xl border border-white/10 bg-white/5 p-4"
                    >
                        <div class="mb-3 flex items-center gap-3">
                            <span class="rounded-full border border-red/40 bg-red/10 px-5 py-2 text-xl font-bold text-red-light">
                                {{ label }}
                            </span>
                            <span class="text-xs text-white/40">{{ renderableData[label].length }} saved</span>
                        </div>

                        <!-- code view: each character's JSON-style grid block -->
                        <div v-if="isCodeView" class="flex flex-col gap-4">
                            <div
                                v-for="char in renderableData[label]"
                                :key="char.id"
                                class="relative"
                            >
                                <button
                                    class="btn btn-circle btn-xs absolute -right-2 -top-2 z-10 border border-white/20 bg-deepblue text-white/70 transition-colors hover:border-red hover:bg-red hover:text-white focus-ring"
                                    @click="deleteCharacter(char.id)"
                                    aria-label="Delete character"
                                >
                                    <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        width="10px"
                                        height="10px"
                                        viewBox="0 0 122.878 122.88"
                                        fill="currentColor"
                                    >
                                        <path
                                            d="M1.426,8.313c-1.901-1.901-1.901-4.984,0-6.886c1.901-1.902,4.984-1.902,6.886,0
                                            l53.127,53.127l53.127-53.127c1.901-1.902,4.984-1.902,6.887,0c1.901,1.901,1.901,4.985,0,6.886L68.324,61.439
                                            l53.128,53.128c1.901,1.901,1.901,4.984,0,6.886c-1.902,1.902-4.985,1.902-6.887,0L61.438,68.326L8.312,121.453
                                            c-1.901,1.902-4.984,1.902-6.886,0c-1.901-1.901-1.901-4.984,0-6.886l53.127-53.128L1.426,8.313L1.426,8.313z"
                                        />
                                    </svg>
                                </button>
                                <div class="mockup-code w-full pe-10">
                                    <pre
                                        v-for="(row, idx) in char['grid']"
                                        :data-prefix="1 + idx"
                                    ><code><span class="text-white/40">{{ idx == 0 ? "[" : " " }}[</span><template v-for="(cell, i) in row" :key="i"><span :class="cell === 1 ? 'text-red-light' : 'text-violet-300'">{{ cell }}</span><span v-if="i < row.length - 1" class="text-white">,</span></template><span class="text-white/40">]{{ idx + 1 == dimension ? "]" : "," }}</span></code></pre>
                                </div>
                            </div>
                        </div>

                        <!-- grid view: each character rendered onto its own mini
                             canvas, reusing the same drawing logic (including the
                             writing-line guide row) as the main writing canvas.
                             Sized close to a code block's footprint so the modal
                             doesn't jump in size when switching between modes. -->
                        <div v-else class="flex flex-wrap gap-4">
                            <div
                                v-for="char in renderableData[label]"
                                :key="char.id"
                                class="relative"
                            >
                                <button
                                    class="btn btn-circle btn-xs absolute -right-2 -top-2 z-10 border border-white/20 bg-deepblue text-white/70 transition-colors hover:border-red hover:bg-red hover:text-white focus-ring"
                                    @click="deleteCharacter(char.id)"
                                    aria-label="Delete character"
                                >
                                    <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        width="10px"
                                        height="10px"
                                        viewBox="0 0 122.878 122.88"
                                        fill="currentColor"
                                    >
                                        <path
                                            d="M1.426,8.313c-1.901-1.901-1.901-4.984,0-6.886c1.901-1.902,4.984-1.902,6.886,0
                                            l53.127,53.127l53.127-53.127c1.901-1.902,4.984-1.902,6.887,0c1.901,1.901,1.901,4.985,0,6.886L68.324,61.439
                                            l53.128,53.128c1.901,1.901,1.901,4.984,0,6.886c-1.902,1.902-4.985,1.902-6.887,0L61.438,68.326L8.312,121.453
                                            c-1.901,1.902-4.984,1.902-6.886,0c-1.901-1.901-1.901-4.984,0-6.886l53.127-53.128L1.426,8.313L1.426,8.313z"
                                        />
                                    </svg>
                                </button>
                                <canvas
                                    :ref="el => drawCharacterCanvas(el, char)"
                                    class="aspect-square w-80 max-w-full touch-none rounded-xl border border-white/10 shadow-lg shadow-black/30"
                                ></canvas>
                            </div>
                        </div>
                    </div>
                </div>
            </template>
        </div>
    </dialog>
</template>

<style scoped></style>
