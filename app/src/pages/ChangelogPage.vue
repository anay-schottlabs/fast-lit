<script setup>
import Header from '../components/Header.vue';
import { ChangelogScripts } from '@/assets/textScripts.js';
</script>

<template>
    <div>
        <Header pageName="Changelog" />

        <!-- changelog -->
        <!-- essentially a list of versions and changes -->
        <ul class="list mt-10">
            <li
                class="list-row"
                v-for="(entry, idx) in [...ChangelogScripts.changelog].reverse()"
                :key="entry.version"
            >
                <!-- Display the entry index in descending order as a two-digit number (e.g., 02, 01) -->
                <div class="text-4xl font-thin opacity-30 tabular-nums">
                    {{ String(ChangelogScripts.changelog.length - idx).padStart(2, '0') }}
                </div>
                <div class="list-col-grow flex flex-col justify-center">
                    <!-- Date of the release -->
                    <div class="text-gray-300 text-lg mb-1">{{ entry.date }}</div>
                    <!-- Version number in red, monospace font -->
                    <div class="text-2xl font-mono !text-red mb-1">{{ entry.version }}</div>
                    <!-- Change description for this version -->
                    <div class="text-lg">{{ entry.changes }}</div>
                </div>
            </li>
        </ul>
    </div>
</template>

<style scoped></style>
