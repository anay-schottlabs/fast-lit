<script setup>
import Header from '../components/Header.vue';
import { useRouter } from 'vue-router';
import { HomeScripts } from '@/assets/textScripts.js';

const router = useRouter();

function navigateTo(path) {
    router.push(path);
}
</script>

<template>
    <div>
        <Header pageName="" />
        <div class="hero min-h-screen">
            <div class="hero-content text-center">
                <div class="max-w-3xl mx-auto px-4">
                    <h1 class="text-7xl font-bold text-red whitespace-normal">
                        {{ HomeScripts.heroTitle }}
                    </h1>
                    <p class="py-6">
                        {{ HomeScripts.heroContent }}
                    </p>
                    <button
                        class="btn btn-wide bg-red hover:opacity-80 relative"
                        @click="navigateTo('/read')"
                    >
                        <span class="w-full text-center">
                            {{ HomeScripts.heroButton }}
                        </span>
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="white"
                            viewBox="0 0 24 24"
                            width="28"
                            height="28"
                            class="absolute right-4 top-1/2 -translate-y-1/2"
                        >
                            <path
                                d="M5 12h14M13 6l6 6-6 6"
                                stroke="white"
                                stroke-width="2.2"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                fill="none"
                            />
                        </svg>
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
