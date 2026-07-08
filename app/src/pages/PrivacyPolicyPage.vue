<script setup>
import Header from '../components/Header.vue';
import { PrivacyScripts } from '@/assets/textScripts.js';
</script>

<template>
    <div class="mx-auto max-w-3xl px-4 pb-24 pt-16">
        <Header pageName="Privacy Policy" />

        <div class="mt-10 rounded-3xl border border-white/10 bg-white/5 p-10 shadow-2xl shadow-black/40">
            <h1 class="text-3xl font-bold !text-red">{{ PrivacyScripts.title }}</h1>
            <p class="mt-2 text-sm text-white/50">{{ PrivacyScripts.lastUpdated }}</p>
            <p class="mt-6 text-white/80">{{ PrivacyScripts.intro }}</p>

            <div
                v-for="section in PrivacyScripts.sections"
                :key="section.heading"
                class="mt-8 border-t border-white/10 pt-8"
            >
                <h2 class="mb-3 text-xl font-semibold">{{ section.heading }}</h2>
                <p
                    v-for="paragraph in section.paragraphs"
                    :key="paragraph"
                    class="mb-3 text-white/80"
                >
                    {{ paragraph }}
                </p>
                <ul
                    v-if="section.list"
                    class="mb-3 list-inside list-disc space-y-1 text-white/80"
                >
                    <li v-for="item in section.list" :key="item">{{ item }}</li>
                </ul>
                <p
                    v-for="paragraph in section.after"
                    :key="paragraph"
                    class="text-white/80"
                >
                    {{ paragraph }}
                </p>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
