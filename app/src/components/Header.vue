<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

function navigateTo(path) {
    router.push(path);
}

const props = defineProps({
    pageName: {
        type: String,
    }
})
</script>

<template>
    <button
        class="btn btn-ghost p-0 focus-ring transition-opacity duration-150 hover:opacity-80"
        style="background: none; box-shadow: none; border: none; color: inherit;"
        @click="navigateTo('/')"
    >
        <div class="text-4xl font-bold flex items-center space-x-3">
            <!-- logo: a ring around a dot, the same "orbit" motif the iOS
                 app's mascot uses -->
            <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 100 100"
                width="40"
                height="40"
                aria-hidden="true"
            >
                <circle cx="50" cy="50" r="34" fill="none" stroke="#E8794F" stroke-width="7" opacity="0.35" />
                <circle cx="50" cy="50" r="16" fill="#E8794F" />
            </svg>

            <!-- name of website -->
            <span class="!text-ink">Orbit</span>

            <!-- name of page -->
            <span class="!text-terracotta" v-if="props.pageName">{{ props.pageName }}</span>
        </div>
    </button>
</template>

<style scoped></style>
