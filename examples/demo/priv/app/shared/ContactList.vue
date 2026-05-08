<script setup lang="ts">
defineProps({
    data: Array<{ id: string; name: string; email: string }>,
});
</script>

<template>
    <div class="flex flex-col rounded border border-indigo-300 p-2">
        <h3 class="font-semibold">Contacts</h3>
        <ul class="flex flex-col gap-1 rounded">
            <li v-for="c in data" :key="c.id" class="rounded bg-gray-200 p-2">
                <div class="flex flex-col gap-1">
                    <span>{{ c.name }}</span>
                    <span class="text-sm">{{ c.email }}</span>
                </div>
            </li>
        </ul>
    </div>
</template>
