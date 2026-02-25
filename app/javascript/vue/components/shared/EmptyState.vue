<template>
  <div class="text-center py-12">
    <component :is="icon" v-if="icon" class="mx-auto h-12 w-12 text-gray-400" />
    <h3 class="mt-2 text-sm font-semibold text-gray-900">{{ title }}</h3>
    <p class="mt-1 text-sm text-gray-500">{{ message }}</p>
  </div>
</template>

<script setup>
defineProps({
  icon: { type: Object, default: null },
  title: { type: String, default: "No data" },
  message: { type: String, default: "No records found." },
})
</script>
