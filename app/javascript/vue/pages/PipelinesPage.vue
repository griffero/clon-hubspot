<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-900 mb-6">Pipelines</h1>

    <LoadingSpinner v-if="store.loading" />

    <template v-else>
      <EmptyState v-if="store.pipelines.length === 0" title="No pipelines" message="No pipelines found. Run a sync first." />

      <div v-else class="space-y-4">
        <div
          v-for="pipeline in store.pipelines"
          :key="pipeline.id"
          class="bg-white rounded-lg border border-gray-200 p-6"
        >
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-gray-900">{{ pipeline.label }}</h2>
            <div class="flex items-center gap-4 text-sm text-gray-500">
              <span>{{ pipeline.stage_count }} stages</span>
              <span>{{ pipeline.deal_count }} deals</span>
              <span class="font-semibold text-green-600">{{ formatCurrency(pipeline.total_value) }}</span>
            </div>
          </div>
          <div class="flex gap-2 flex-wrap">
            <div
              v-for="(stage, idx) in pipelineStages[pipeline.id]"
              :key="stage.id"
              class="flex items-center gap-1"
            >
              <div class="bg-gray-100 rounded-lg px-3 py-2 text-center min-w-[120px]">
                <p class="text-xs font-medium text-gray-700 truncate">{{ stage.label }}</p>
                <p class="text-xs text-gray-500">{{ stage.deal_count }} deals</p>
                <p class="text-xs text-green-600 font-medium">{{ formatCurrency(stage.total_value) }}</p>
              </div>
              <ChevronRightIcon v-if="idx < pipelineStages[pipeline.id].length - 1" class="w-4 h-4 text-gray-400 flex-shrink-0" />
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue"
import { usePipelinesStore } from "../stores/pipelines.js"
import { ChevronRightIcon } from "@heroicons/vue/24/outline"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"
import EmptyState from "../components/shared/EmptyState.vue"
import pipelinesApi from "../api/pipelines.js"

const store = usePipelinesStore()
const pipelineStages = ref({})

onMounted(async () => {
  await store.fetchPipelines()
  for (const p of store.pipelines) {
    const data = await pipelinesApi.get(p.id)
    pipelineStages.value[p.id] = data.pipeline.stages
  }
})

function formatCurrency(amount) {
  if (!amount) return "$0"
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(amount)
}
</script>
