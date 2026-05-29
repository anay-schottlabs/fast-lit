<script setup>
import Reader from './components/Reader.vue';
import TextBox from './components/TextBox.vue';
</script>

<template>
    <div class="d-flex flex-column vh-100 p-3">
        <div class="row">
            <h1>Speed Reader</h1>
        </div>
        <div class="row flex-grow-1">
            <div class="col border border-2 border-black p-1">
                <Reader />
            </div>
            <div class="col border border-2 border-black p-1">
                <TextBox />
            </div>
        </div>
    </div>
</template>

<style scoped></style>
