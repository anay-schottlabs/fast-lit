<script setup>
import { ref } from 'vue';

import Reader from './components/Reader.vue';
import TextBox from './components/TextBox.vue';

const text = ref("");

function textUpdate(newText) {
    text.value = newText;
}
</script>

<template>
    <div class="d-flex flex-column vh-100 p-3">
        <div class="row text-center">
            <p class="fs-1 fw-bold">Speed Reader</p>
        </div>
        <div class="row flex-grow-1">
            <div class="col p-1">
                <Reader :text="text" />
            </div>
            <div class="col p-1">
                <TextBox @textUpdate="textUpdate" />
            </div>
        </div>
    </div>
</template>

<style scoped></style>
