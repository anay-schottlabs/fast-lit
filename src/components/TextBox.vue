<script setup></script>

<template>
    <!-- .form-control gives textarea the full width -->
    <!-- .h-100 gives textarea the full height -->
    <textarea
        class="form-control h-100"
        placeholder="Paste some text to start reading..."
    ></textarea>
</template>

<style scoped>
/* prevents textarea from being rescaled */
textarea {
    resize: none;
}
</style>
