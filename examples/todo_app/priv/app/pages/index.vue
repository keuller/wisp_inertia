<script setup lang="ts">
import { Head, Form } from "@inertiajs/vue3";
import TaskItem from "../shared/task_item.vue";

defineProps({
    tasks: Array<{ id: string; title: string; description: string }>,
});
</script>

<template>
    <Head title="Wisp Inertia Todo" />
    <h1 class="text-indigo-800 font-bold py-2 text-2xl text-center">TODO</h1>
    <div class="flex flex-col">
        <div id="form" class="py-2 px-4">
            <Form method="post" action="/">
                <div class="flex items-center gap-3">
                    <label for="task" class="text-sm">Task:</label>
                    <input
                        id="task"
                        type="text"
                        name="title"
                        class="border border-gray-400 px-2 py-1 w-full text-sm rounded"
                        maxlength="40"
                    />
                    <button type="submit" class="rounded px-4 py-1 text-sm border border-slate-400">Add</button>
                </div>
            </Form>
        </div>
        <div id="items" class="text-blue-800">
            <template v-for="item in tasks" :key="item.id">
                <TaskItem :item="item" />
            </template>
            <div
                v-if="tasks?.length === 0"
                class="rounded text-sm font-semibold mt-2 p-2 bg-gray-100 text-slate-400 text-center"
            >
                No tasks found :(
            </div>
        </div>
    </div>
</template>
