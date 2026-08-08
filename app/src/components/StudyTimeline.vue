<script setup>
// A numbered walkthrough of the study's phases (practice, then one entry per
// speed covering that speed's regular + RSVP pair), each with a short
// description and a rough time estimate, plus a distinct total at the
// bottom — used on the /lab start screen.
defineProps({
    phases: {
        type: Array, // [{ label, detail, minutes }]
        required: true
    },
    totalMinutes: {
        type: Number,
        required: true
    }
});
</script>

<template>
    <div class="rounded-2xl border border-border bg-bg p-5">
        <div class="flex flex-col gap-4">
            <div v-for="(phase, i) in phases" :key="phase.label" class="flex items-start gap-3">
                <div
                    class="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-ink/10 text-xs font-bold !text-ink"
                >
                    {{ i + 1 }}
                </div>
                <div class="min-w-0 flex-1">
                    <div class="flex items-baseline justify-between gap-4">
                        <span class="font-semibold !text-ink">{{ phase.label }}</span>
                        <span class="shrink-0 font-mono text-sm !text-ink-light">~{{ phase.minutes.toFixed(1) }} min</span>
                    </div>
                    <p class="text-sm !text-ink-light">{{ phase.detail }}</p>
                </div>
            </div>
        </div>

        <div class="mt-5 flex items-baseline justify-between border-t border-border pt-4">
            <span class="font-semibold !text-ink">Total</span>
            <span class="font-mono font-semibold !text-ink">
                ~{{ Math.round(totalMinutes) }}–{{ Math.round(totalMinutes * 1.5) }} min
            </span>
        </div>
    </div>
</template>

<style scoped></style>
