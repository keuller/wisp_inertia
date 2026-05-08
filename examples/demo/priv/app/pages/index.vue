<script setup lang="ts">
import { Head, Deferred } from "@inertiajs/vue3";
import ContactList from "../shared/ContactList.vue";
import Notifications from "../shared/Notifications.vue";

defineProps({
    title: String,
    contacts: Array,
    messages: Array<{ text: string; created_on: string }>,
});
</script>

<template>
    <Head title="Wisp Inertia" />
    <h1 class="text-blue-700 font-bold py-2 text-2xl text-center">{{ title }}</h1>
    <div class="grid grid-cols-2 gap-3">
        <Deferred data="contacts">
            <template #fallback>
                <div class="flex flex-col rounded border border-indigo-300 p-2">
                    <span class="text-sm animate-pulse">Loading...</span>
                </div>
            </template>
            <ContactList :data="contacts" />
        </Deferred>
        <Notifications :messages="messages" />
    </div>
</template>
