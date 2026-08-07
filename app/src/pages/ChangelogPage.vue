<script setup>
import Header from '../components/Header.vue';
import { ChangelogScripts } from '@/assets/textScripts.js';
</script>

<template>
    <div>
        <Header pageName="Changelog" />

        <!-- changelog -->
        <!-- a list of version cards, styled to match the Fast Lit Grabber extension popup -->
        <div class="max-w-2xl mx-auto px-4 mt-10 mb-20 flex flex-col gap-6">
            <div
                class="rounded-2xl border border-border bg-card card-shadow p-6"
                v-for="(entry, idx) in [...ChangelogScripts.changelog].reverse()"
                :key="entry.version"
            >
                <!-- version pill, latest badge, and release date -->
                <div class="flex items-center flex-wrap gap-3 mb-4">
                    <span class="rounded-full bg-terracotta px-3 py-1 text-sm font-mono font-bold !text-cream">
                        v{{ entry.version }}
                    </span>
                    <span
                        v-if="idx === 0"
                        class="rounded-full bg-ink/10 px-3 py-1 text-xs font-semibold uppercase tracking-wide !text-ink-light"
                    >Latest</span>
                    <span class="ms-auto text-sm !text-ink-light">{{ entry.date }}</span>
                </div>

                <!-- changes for this version, numbered like the extension popup's steps -->
                <ul class="flex flex-col gap-3">
                    <li
                        class="flex items-start gap-3"
                        v-for="(change, changeIdx) in entry.changes"
                        :key="changeIdx"
                    >
                        <span
                            class="
                                flex
                                h-6
                                w-6
                                flex-shrink-0
                                items-center
                                justify-center
                                rounded-full
                                bg-ink/10
                                !text-ink-light
                                text-xs
                                font-bold
                            "
                        >
                            {{ changeIdx + 1 }}
                        </span>
                        <p class="mb-0 leading-snug !text-ink">{{ change }}</p>
                    </li>
                </ul>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
