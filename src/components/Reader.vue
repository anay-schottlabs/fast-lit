<script setup>
import { ref } from 'vue';

// enum to manage reader states
const PlayState = Object.freeze({
    STOPPED: "stopped",
    PAUSED: "paused",
    PLAYING: "playing"
});

const playState = ref(PlayState.STOPPED)

function parse() {
}

function start() {
    playState.value = PlayState.PLAYING;
}

function pause() {
    playState.value = PlayState.PAUSED;
}

function end() {
    playState.value = PlayState.STOPPED;
}
</script>

<template>
    <div class="d-flex flex-column">
        <div class="d-grid mb-1">
            <button class="btn btn-secondary" @click="parse">Parse Text</button>
        </div>
        <div class="btn-group">
            <button
                class="btn btn-primary"
                v-if="playState != PlayState.PLAYING"
                @click="start"
            >{{ playState == PlayState.PAUSED ? "Continue Reader" : "Start Reader" }}</button>
            <button
                class="btn btn-warning"
                v-if="playState == PlayState.PLAYING"
                @click="pause"
            >Pause Reader</button>
            <button
                class="btn btn-danger"
                v-if="playState != PlayState.STOPPED"
                @click="end"
            >End Reader</button>
        </div>
    </div>
</template>

<style scoped></style>
