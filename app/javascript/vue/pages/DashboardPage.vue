<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-900 mb-6">Dashboard</h1>

    <LoadingSpinner v-if="loading" />

    <template v-else>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <p class="text-sm text-gray-500">Total Deals</p>
          <p class="text-3xl font-bold text-gray-900 mt-1">{{ stats.totalDeals }}</p>
        </div>
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <p class="text-sm text-gray-500">Total Contacts</p>
          <p class="text-3xl font-bold text-gray-900 mt-1">{{ stats.totalContacts }}</p>
        </div>
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <p class="text-sm text-gray-500">Total Companies</p>
          <p class="text-3xl font-bold text-gray-900 mt-1">{{ stats.totalCompanies }}</p>
        </div>
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <p class="text-sm text-gray-500">Total Deal Value</p>
          <p class="text-3xl font-bold text-green-600 mt-1">{{ formatCurrency(stats.totalValue) }}</p>
        </div>
      </div>

      <div v-if="pipelines.length" class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Deal Value by Pipeline</h2>
        <div class="space-y-3">
          <div v-for="p in pipelines" :key="p.id" class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span class="text-sm font-medium text-gray-900">{{ p.label }}</span>
              <span class="text-xs text-gray-500">{{ p.deal_count }} deals</span>
            </div>
            <span class="text-sm font-semibold text-green-600">{{ formatCurrency(p.total_value) }}</span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from "vue"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"
import pipelinesApi from "../api/pipelines.js"
import contactsApi from "../api/contacts.js"
import companiesApi from "../api/companies.js"
import dealsApi from "../api/deals.js"

const loading = ref(true)
const pipelines = ref([])
const stats = reactive({
  totalDeals: 0,
  totalContacts: 0,
  totalCompanies: 0,
  totalValue: 0,
})

onMounted(async () => {
  try {
    const [pData, cData, coData, dData] = await Promise.all([
      pipelinesApi.list(),
      contactsApi.list({ per_page: 1 }),
      companiesApi.list({ per_page: 1 }),
      dealsApi.list({ per_page: 1 }),
    ])

    pipelines.value = pData.pipelines
    stats.totalContacts = cData.pagination?.count || 0
    stats.totalCompanies = coData.pagination?.count || 0
    stats.totalDeals = dData.pagination?.count || 0
    stats.totalValue = pData.pipelines.reduce((sum, p) => sum + (parseFloat(p.total_value) || 0), 0)
  } finally {
    loading.value = false
  }
})

function formatCurrency(amount) {
  if (!amount) return "$0"
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(amount)
}
</script>
