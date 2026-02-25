<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Deals</h1>
      <div class="flex items-center gap-3">
        <select
          v-model="selectedPipeline"
          @change="loadData"
          class="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-500"
        >
          <option v-for="p in pipelines" :key="p.id" :value="p.id">{{ p.label }}</option>
        </select>
        <div class="flex border border-gray-300 rounded-lg overflow-hidden">
          <button
            @click="viewMode = 'kanban'"
            class="px-3 py-2 text-sm"
            :class="viewMode === 'kanban' ? 'bg-orange-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-50'"
          >
            Board
          </button>
          <button
            @click="viewMode = 'table'; loadTableData()"
            class="px-3 py-2 text-sm"
            :class="viewMode === 'table' ? 'bg-orange-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-50'"
          >
            Table
          </button>
        </div>
      </div>
    </div>

    <LoadingSpinner v-if="store.loading" />

    <template v-else>
      <DealsKanban v-if="viewMode === 'kanban' && store.kanbanData" :stages="store.kanbanData.stages" />

      <div v-if="viewMode === 'table'">
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Stage</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Close Date</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="deal in store.deals" :key="deal.id" class="hover:bg-gray-50">
                <td class="px-6 py-4">
                  <router-link :to="{ name: 'deal', params: { id: deal.id } }" class="text-sm font-medium text-orange-600 hover:text-orange-800">
                    {{ deal.name }}
                  </router-link>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ deal.amount ? formatCurrency(deal.amount) : '-' }}</td>
                <td class="px-6 py-4 text-sm text-gray-500">{{ deal.stage_name }}</td>
                <td class="px-6 py-4 text-sm text-gray-500">{{ deal.close_date ? formatDate(deal.close_date) : '-' }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <Pagination :pagination="store.pagination" @page-change="(p) => loadTableData(p)" />
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue"
import { useDealsStore } from "../stores/deals.js"
import { usePipelinesStore } from "../stores/pipelines.js"
import DealsKanban from "../components/deals/DealsKanban.vue"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"
import Pagination from "../components/shared/Pagination.vue"

const store = useDealsStore()
const pipelinesStore = usePipelinesStore()
const viewMode = ref("kanban")
const selectedPipeline = ref(null)
const pipelines = ref([])

onMounted(async () => {
  await pipelinesStore.fetchPipelines()
  pipelines.value = pipelinesStore.pipelines
  if (pipelines.value.length > 0) {
    selectedPipeline.value = pipelines.value[0].id
  }
  loadData()
})

function loadData() {
  if (viewMode.value === "kanban") {
    store.fetchKanban({ pipeline_id: selectedPipeline.value })
  } else {
    loadTableData()
  }
}

function loadTableData(page = 1) {
  store.fetchDeals({ pipeline_id: selectedPipeline.value, page })
}

function formatCurrency(amount) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount)
}

function formatDate(date) {
  return new Date(date).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
}
</script>
