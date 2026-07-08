<script setup>
import Header from '../components/Header.vue';
import { ref, watch, onMounted, onUnmounted, render } from 'vue';
import { WriteScripts } from '@/assets/textScripts.js';

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

// Renders the whole grid from scratch onto the canvas. Called on mount and
// whenever `grid` changes (see the `watch` below) — there's no incremental
// redraw, the canvas is cleared and every cell is repainted each time.
function drawGrid() {
    const el = canvas.value;
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
            const isOn = grid.value[row][col] === 1;
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

function recognizeCharacter() {
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

// watch data's value so that we can create renderableData
// so that data can more easily be parsed and displayed in the html
watch(data, (newData) => {
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
</script>

<template>
    <Header pageName="Write" />

    <!-- main page content, constrained/centered like every other page so the
         character row and canvas share one column instead of drifting apart
         (the row was previously flush-left while the canvas centered itself) -->
    <div class="mx-auto max-w-2xl p-5">
        <ul class="menu menu-vertical lg:menu-horizontal bg-base-200 rounded-box">
            <li>
                <a
                    :class="{ 'active': currentPage === Pages.WRITE }"
                    @click="currentPage = Pages.WRITE"
                >Write</a>
            </li>
            <li>
                <a
                    :class="{ 'active': currentPage === Pages.LEARN }"
                    @click="currentPage = Pages.LEARN"
                >Learn</a>
            </li>
            <li>
                <a
                    :class="{ 'active': currentPage === Pages.DEVELOPER }"
                    @click="currentPage = Pages.DEVELOPER"
                >Developer</a>
            </li>
        </ul>

        <!-- write page -->
        <div
            v-if="currentPage == Pages.WRITE"
            class="my-5 min-h-16 rounded-2xl border border-white/10 bg-white/5 p-4 flex flex-wrap items-center justify-center gap-2"
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
            class="my-5 min-h-16 rounded-2xl border border-white/10 bg-white/5 p-4 flex flex-wrap items-center justify-center gap-2"
        >
            <p>learn page</p>
        </div>

        <!-- developer page -->
        <div
            v-if="currentPage == Pages.DEVELOPER"
            class="my-5 min-h-16 rounded-2xl border border-white/10 bg-white/5 p-4 flex flex-wrap items-center justify-center gap-2"
        >
            <!-- set chars to label data -->
            <input
                class="input w-full"
                v-model="currentLabel"
                :placeholder="WriteScripts.devCharInputPlaceholder"
            >

            <!-- export data -->
            <div>
                <button class="btn" @click="isViewJsonModalOpen = true">View json</button>
                <button class="btn" @click="exportJson">Download json</button>
            </div>

            <!-- accordion to view all data -->
            <details 
                class="collapse collapse-arrow bg-base-100 border border-base-300"
                :open="isDataOpen"
                @toggle="isDataOpen = $event.target.open"
            >
                <summary class="collapse-title font-semibold">
                    {{ isDataOpen ? WriteScripts.accordionHeaderOpen : WriteScripts.accordionHeaderClosed }} ({{ data.length }})
                    <div class="ms-50">
                        Grid
                        <input
                            type="checkbox"
                            :checked="isCodeView"
                            @change="isCodeView = $event.target.checked"                       
                            class="toggle toggle-xl"
                        />
                        Code
                    </div>
                </summary>
                <div class="collapse-content text-sm">
                    <div v-for="label in Object.keys(renderableData)">
                        <kbd
                            class="kbd kbd-xl rounded-lg bg-white text-gray-800 border border-gray-300 shadow"
                        >{{ label }}</kbd>
                        <div v-for="char in renderableData[label]"> 

                            <!-- if this is code view -->
                            <div v-if="isCodeView" class="mockup-code w-full">
                                <pre
                                    v-for="(row, idx) in char['grid']"
                                    :data-prefix="1 + idx"
                                ><code>{{ idx == 0 ? "[" : " " }}[{{ row.toString() }}]{{ idx + 1 == dimension ? "]" : "," }}</code></pre>
                            </div>

                            <!-- if this is grid view -->
                             <div v-if="!isCodeView">
                                GRID HERE (PLACEHOLDER)
                             </div>
                        </div>
                    </div>
                </div>
            </details>
        </div>

        <canvas
            id="drawCanvas"
            class="aspect-square touch-none rounded-2xl mx-auto w-[min(90vw,65vh,32rem)] border border-white/10 shadow-2xl shadow-black/40"
        ></canvas>
    </div>

    <!-- view json modal — contents intentionally blank for now, styling TBD -->
    <dialog
        class="modal"
        :class="{ 'modal-open': isViewJsonModalOpen }"
    >
        <div class="modal-box">
            <button @click="isViewJsonModalOpen = false">Close</button>

            <!-- if this is code view -->
            <div class="mockup-code w-full">
                <pre data-prefix="1"><code>[</code></pre>
                <div v-for="(char, idx1) in data">
                    <pre
                        :data-prefix="2 + (idx1 * 26)"
                    ><code>{{ indent + "{" }}</code></pre>
                    <pre
                        :data-prefix="3 + (idx1 * 26)"
                    ><code>{{ indent + indent }}"id": "{{ char["id"] }}",</code></pre>
                    <pre
                        :data-prefix="4 + (idx1 * 26)"
                    ><code>{{ indent + indent }}"label": "{{ char["label"] }}",</code></pre>
                    <pre
                        :data-prefix="5 + (idx1 * 26)"
                    ><code>{{ indent + indent }}"grid": [</code></pre>
                    <pre
                        v-for="(row, idx2) in char['grid']"
                        :data-prefix="6 + (idx1 * 26) + idx2"
                    ><code>{{ indent + indent + indent }}[ {{ row.toString() }} ]{{ idx2 + 1 != dimension ? "," : "" }}</code></pre>
                    <pre
                        :data-prefix="26 + (idx1 * 26)"
                    ><code>{{ indent + indent }}]</code></pre>
                    <pre
                        :data-prefix="27 + (idx1 * 26)"
                    ><code>{{ indent + "}" }}</code></pre>
                </div>
                <pre
                    :data-prefix="28 + ((data.length - 1) * 26)"
                ><code>]</code></pre>
                <pre
                    :data-prefix="29 + ((data.length - 1) * 26)"
                ><code></code></pre>
            </div>
        </div>
    </dialog>
</template>

<style scoped></style>
