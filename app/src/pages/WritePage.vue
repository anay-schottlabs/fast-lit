<script setup>
import Header from '../components/Header.vue';
import { ref, watch, onMounted, onUnmounted } from 'vue';

const canvas = ref(null);

const colorCanvasBackground = '#120A3D';              // matches main page background
const colorCellOff = '#1A124D';                       // slightly lighter for grid off-cells
const colorCellOn = '#F3EFFE';                        // very light for on-cells; warm off-white
const colorWritingLineOff = '#38297A';                // dark purple for sub-lines/guide lines

const gridGap = 0.01;
const innerCornerRadius = 0.4;
const dimension = 20;
const writingLineDivisions = 4;
const writingLineFraction = (writingLineDivisions - 1) / writingLineDivisions;
const writingLineRow = Math.round(writingLineFraction * dimension);
const grid = ref(Array.from({ length: dimension }, () => Array(dimension).fill(0)));

function getGridLayout(size) {
    const gap = size * gridGap;
    const padding = gap;
    const available = size - 2 * padding - (dimension - 1) * gap;
    const cellSize = available / dimension;
    return { gap, padding, cellSize };
}

function getNearestCellIndex(local, pitch, cellSize) {
    const index = Math.round((local - cellSize / 2) / pitch);
    return Math.min(dimension - 1, Math.max(0, index));
}

function getCellsFromPoint(x, y, layout) {
    const { padding, cellSize } = layout;
    const pitch = cellSize + layout.gap;

    const localX = x - padding;
    const localY = y - padding;

    const col = getNearestCellIndex(localX, pitch, cellSize);
    const row = getNearestCellIndex(localY, pitch, cellSize);

    return [{ row, col }];
}

function clampRadius(radius, cellSize) {
    return Math.min(radius, cellSize / 2);
}

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

function drawGrid() {
    const el = canvas.value;
    if (!el) return;

    const ctx = el.getContext('2d');
    const dpr = window.devicePixelRatio || 1;
    const rect = el.getBoundingClientRect();
    const size = rect.width;

    el.width = size * dpr;
    el.height = size * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const { gap, padding, cellSize } = getGridLayout(size);
    const canvasCornerRadius = parseFloat(getComputedStyle(el).borderTopLeftRadius) || 16;

    ctx.fillStyle = colorCanvasBackground;
    ctx.fillRect(0, 0, size, size);

    for (let row = 0; row < dimension; row++) {
        for (let col = 0; col < dimension; col++) {
            const x = padding + col * (cellSize + gap);
            const y = padding + row * (cellSize + gap);

            const isOn = grid.value[row][col] === 1;
            const isWritingLine = row === writingLineRow;
            ctx.fillStyle = isOn ? colorCellOn : isWritingLine ? colorWritingLineOff : colorCellOff;
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

function handleCanvasClick(x, y) {
    const el = canvas.value;
    if (!el) return;

    const layout = getGridLayout(el.getBoundingClientRect().width);
    const cells = getCellsFromPoint(x, y, layout);

    for (const { row, col } of cells) {
        grid.value[row][col] = 1;
    }
}

let isDrawing = false;

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

function onPointerDown(event) {
    isDrawing = true;

    const point = getCanvasPoint(event);
    if (point) {
        handleCanvasClick(point.x, point.y);
    }
}

function onPointerMove(event) {
    if (!isDrawing) return;

    const point = getCanvasPoint(event);
    if (point) {
        handleCanvasClick(point.x, point.y);
    }
}

function onPointerUp() {
    isDrawing = false;
    resetGrid();
}

watch(grid, drawGrid, { deep: true });

function resetGrid() {
    if (!grid.value || !Array.isArray(grid.value)) return;
    for (let row = 0; row < grid.value.length; row++) {
        for (let col = 0; col < grid.value[row].length; col++) {
            grid.value[row][col] = 0;
        }
    }
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
</script>

<template>
    <Header pageName="Write" />
    
    <!-- main page content -->
    <div class="mt-5">
        <canvas
            id="drawCanvas"
            class="aspect-square w-full touch-none rounded-2xl"       
        ></canvas>
    </div>
</template>

<style scoped></style>
