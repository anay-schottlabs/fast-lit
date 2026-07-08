<script setup>
import Header from '../components/Header.vue';
import { PrivacyScripts } from '@/assets/textScripts.js';
</script>

<template>
    <div>
        <Header pageName="Privacy Policy" />

        <div class="mx-auto max-w-3xl px-4 pb-16 pt-10">
            <div class="rounded-3xl border border-white/10 bg-white/5 p-10 shadow-2xl shadow-black/40">
                <span class="inline-block rounded-full border border-red/40 bg-red/10 px-4 py-1 text-xs font-semibold uppercase tracking-widest text-red-light">
                    {{ PrivacyScripts.lastUpdated }}
                </span>
                <h1 class="mt-4 text-3xl font-bold !text-red sm:text-4xl">{{ PrivacyScripts.title }}</h1>
                <p class="mt-6 text-lg text-white/70">{{ PrivacyScripts.intro }}</p>

                <div
                    v-for="(section, idx) in PrivacyScripts.sections"
                    :key="section.heading"
                    class="mt-8 border-t border-white/10 pt-8"
                >
                    <div class="mb-4 flex items-center gap-3">
                        <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-red text-sm font-bold">
                            {{ idx + 1 }}
                        </span>
                        <h2 class="text-xl font-semibold">{{ section.heading }}</h2>
                    </div>

                    <p
                        v-for="paragraph in section.paragraphs"
                        :key="paragraph"
                        class="mb-3 text-white/80"
                    >
                        {{ paragraph }}
                    </p>

                    <ul v-if="section.list" class="mb-3 flex flex-col gap-2">
                        <li
                            v-for="item in section.list"
                            :key="item"
                            class="flex items-start gap-3 text-white/80"
                        >
                            <span class="mt-2.5 h-1.5 w-1.5 shrink-0 rounded-full bg-red"></span>
                            <span>{{ item }}</span>
                        </li>
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

            <p class="mt-8 text-center text-sm text-white/40">&copy; 2026 Fast Lit</p>
        </div>
    </div>
</template>

<style scoped></style>
