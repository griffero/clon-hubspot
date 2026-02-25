<template>
  <div class="flex-shrink-0 w-72 bg-gray-100 rounded-lg flex flex-col max-h-full">
    <div class="p-3 border-b border-gray-200">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-semibold text-gray-700 truncate">{{ stage.label }}</h3>
        <span class="text-xs text-gray-500 bg-gray-200 px-2 py-0.5 rounded-full">
          {{ stage.deals.length }}
        </span>
      </div>
      <p class="text-xs text-gray-500 mt-1">{{ formatCurrency(stage.total_value) }}</p>
    </div>
    <div class="flex-1 overflow-y-auto p-2 space-y-2">
      <draggable
        :list="stage.deals"
        group="deals"
        item-key="id"
        class="space-y-2 min-h-[40px]"
      >
        <template #item="{ element }">
          <KanbanCard :deal="element" />
        </template>
      </draggable>
    </div>
  </div>
</template>

<script setup>
import draggable from "vuedraggable"
import KanbanCard from "./KanbanCard.vue"

defineProps({
  stage: { type: Object, required: true },
})

function formatCurrency(amount) {
  if (!amount) return "$0"
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(amount)
}
</script>
