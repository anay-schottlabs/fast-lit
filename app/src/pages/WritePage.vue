<script setup>
import Header from '../components/Header.vue';
import { ref, watch, onMounted, onUnmounted } from 'vue';

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

// Releasing the pointer ends the current drag and clears the grid.
function onPointerUp() {
    isDrawing = false;
    resetGrid();
}

// Redraw any time the grid data changes.
watch(grid, drawGrid, { deep: true });

function resetGrid() {
    if (!grid.value || !Array.isArray(grid.value)) return;
    for (let row = 0; row < grid.value.length; row++) {
        for (let col = 0; col < grid.value[row].length; col++) {
            grid.value[row][col] = 0;
        }
    }
    recognizeCharacter();
}

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

// character recognition

const characters = ref([]);

function recognizeCharacter() {
    // Check if all entries in the grid are zeroes
    if (
        grid.value &&
        Array.isArray(grid.value) &&
        grid.value.every(row =>
            Array.isArray(row) && row.every(cell => cell === 0)
        )
    ) {
        // Push a random lowercase alphabet character
        const randomChar = String.fromCharCode(97 + Math.floor(Math.random() * 26));
        characters.value.push(randomChar);
    }
}
</script>

<template>
    <Header pageName="Write" />
    
    <!-- main page content -->
    <div>
        <div class="my-5">
            <kbd
                class="kbd kbd-xl bg-white text-gray-800 border border-gray-300 shadow"
                v-for="char in characters"
            >{{ char }}</kbd>
        </div>

        <canvas
            id="drawCanvas"
            class="aspect-square touch-none rounded-2xl mx-auto w-[min(90vw,65vh,32rem)]"
        ></canvas>
    </div>
</template>

<style scoped></style>
