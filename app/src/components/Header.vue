<script setup>
const props = defineProps({
    pageName: {
        type: String,
    }
})
</script>

<template>
    <p class="text-4xl font-bold">
        Fast Lit <span class="text-red">{{ props.pageName }}</span>
    </p>
</template>

<style scoped></style>
