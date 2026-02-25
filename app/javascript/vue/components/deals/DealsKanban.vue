<template>
  <div class="flex gap-4 overflow-x-auto pb-4" style="min-height: 400px;">
    <KanbanColumn v-for="stage in stages" :key="stage.id" :stage="stage" />
    <EmptyState
      v-if="stages.length === 0"
      title="No stages"
      message="This pipeline has no stages."
    />
  </div>
</template>

<script setup>
import KanbanColumn from "./KanbanColumn.vue"
import EmptyState from "../shared/EmptyState.vue"

defineProps({
  stages: { type: Array, default: () => [] },
})
</script>
