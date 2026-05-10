<script setup lang="ts">
import { watch, ref } from "vue";
import { router, usePage } from "@inertiajs/vue3";

const page = usePage();
const eventLog = ref<string[]>([]);

function log(message: string) {
    eventLog.value.unshift(`${new Date().toLocaleTimeString()} - ${message}`);
    if (eventLog.value.length > 5) eventLog.value.pop();
}

function cleanMessages() {
    const tm = setTimeout(() => {
        eventLog.value = [];
        clearTimeout(tm);
    }, 4500);
}

watch(
    () => page.flash,
    (flash) => {
        if (flash.message) {
            log(`Flash received: "${flash.message}"`);
            cleanMessages();
        }
    },
    { deep: true },
);
</script>

<template>
    <div class="flex flex-col rounded border border-indigo-300 p-2">
        <h3 class="font-semibold">Flash Messages</h3>

        <div class="flex items-center">
            <button
                type="button"
                class="text-sm px-4 py-1 border rounded border-blue-400"
                @click="router.post('/flash', {}, { preserveScroll: true, except: ['contacts'] })"
            >
                Test Flash
            </button>
        </div>
        <div v-if="eventLog.length > 0" class="rounded-lg border border-green-400 bg-green-200 p-3 text-sm mt-2">
            {{ page.flash.message }}
        </div>
    </div>
</template>
