<template>
  <div>
    <router-link to="/deals" class="text-sm text-orange-600 hover:text-orange-800 mb-4 inline-block">
      &larr; Back to Deals
    </router-link>

    <LoadingSpinner v-if="store.loading" />

    <template v-else-if="store.currentDeal">
      <div class="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <h1 class="text-2xl font-bold text-gray-900">{{ store.currentDeal.name }}</h1>
        <div class="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <p class="text-xs text-gray-500 uppercase">Amount</p>
            <p class="text-lg font-semibold text-green-600">
              {{ store.currentDeal.amount ? formatCurrency(store.currentDeal.amount) : '-' }}
            </p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Stage</p>
            <p class="text-sm text-gray-900">{{ store.currentDeal.stage_name }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Pipeline</p>
            <p class="text-sm text-gray-900">{{ store.currentDeal.pipeline_name }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Close Date</p>
            <p class="text-sm text-gray-900">{{ store.currentDeal.close_date ? formatDate(store.currentDeal.close_date) : '-' }}</p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Associated Contacts</h2>
          <div v-if="store.currentDeal.contacts?.length" class="space-y-3">
            <router-link
              v-for="contact in store.currentDeal.contacts"
              :key="contact.id"
              :to="{ name: 'contact', params: { id: contact.id } }"
              class="block p-3 border rounded-lg hover:bg-gray-50"
            >
              <p class="text-sm font-medium text-gray-900">{{ contact.name }}</p>
              <p class="text-xs text-gray-500">{{ contact.email }}</p>
            </router-link>
          </div>
          <p v-else class="text-sm text-gray-500">No associated contacts</p>
        </div>

        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Associated Companies</h2>
          <div v-if="store.currentDeal.companies?.length" class="space-y-3">
            <router-link
              v-for="company in store.currentDeal.companies"
              :key="company.id"
              :to="{ name: 'company', params: { id: company.id } }"
              class="block p-3 border rounded-lg hover:bg-gray-50"
            >
              <p class="text-sm font-medium text-gray-900">{{ company.name }}</p>
              <p class="text-xs text-gray-500">{{ company.domain }}</p>
            </router-link>
          </div>
          <p v-else class="text-sm text-gray-500">No associated companies</p>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { onMounted } from "vue"
import { useDealsStore } from "../stores/deals.js"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"

const props = defineProps({ id: { type: [String, Number], required: true } })
const store = useDealsStore()

onMounted(() => store.fetchDeal(props.id))

function formatCurrency(amount) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount)
}

function formatDate(date) {
  return new Date(date).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
}
</script>
