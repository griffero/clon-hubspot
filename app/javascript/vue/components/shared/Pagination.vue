<template>
  <div v-if="pagination && pagination.pages > 1" class="flex items-center justify-between mt-4">
    <p class="text-sm text-gray-500">
      Page {{ pagination.page }} of {{ pagination.pages }} ({{ pagination.count }} total)
    </p>
    <div class="flex gap-2">
      <button
        @click="$emit('page-change', pagination.page - 1)"
        :disabled="pagination.page <= 1"
        class="px-3 py-1 text-sm border rounded-lg disabled:opacity-40 disabled:cursor-not-allowed hover:bg-gray-50"
      >
        Previous
      </button>
      <button
        @click="$emit('page-change', pagination.page + 1)"
        :disabled="pagination.page >= pagination.pages"
        class="px-3 py-1 text-sm border rounded-lg disabled:opacity-40 disabled:cursor-not-allowed hover:bg-gray-50"
      >
        Next
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({
  pagination: { type: Object, default: null },
})
defineEmits(["page-change"])
</script>
