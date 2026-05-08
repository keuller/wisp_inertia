<script setup lang="ts">
import { router } from "@inertiajs/vue3";

defineProps({
    messages: Array<{ text: string; created_on: string }>,
});

function add() {
    router.reload({
        only: ["messages"],
    });
}

function reset() {
    router.reload({
        reset: ["messages"],
    });
}
</script>

<template>
    <div class="flex flex-col gap-2 rounded border border-indigo-300 p-2">
        <h3 class="font-semibold">Notifications</h3>

        <div class="flex items-center gap-2">
            <button type="button" class="border rounded px-4 py-1 border-slate-300 text-sm" @click.prevent="add">
                Add
            </button>

            <button type="button" class="border rounded px-4 py-1 border-slate-300 text-sm" @click.prevent="reset">
                Reset
            </button>
        </div>
        <ul class="flex flex-col gap-2 py-2">
            <li class="border border-gray-400 rounded px-2 py-1" v-for="item in messages">
                <div class="flex items-center gap-2 justify-between">
                    <span>{{ item.text }}</span>
                    <span class="text-sm text-gray-400">{{ item.created_on }}</span>
                </div>
            </li>
        </ul>
    </div>
</template>
