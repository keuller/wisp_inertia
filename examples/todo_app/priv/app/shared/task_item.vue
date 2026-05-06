<script setup lang="ts">
import { Link } from "@inertiajs/vue3";

type Props = {
    item: {
        id: string;
        title: string;
        completed: boolean;
    };
};

defineProps<Props>();
</script>

<template>
    <div class="flex items-center justify-between rounded border mt-4 p-4">
        <div class="text-sm">{{ item.title }}</div>
        <Link :href="item.id" method="delete">Remove</Link>
    </div>
</template>
