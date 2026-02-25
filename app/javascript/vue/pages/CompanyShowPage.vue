<template>
  <div>
    <router-link to="/companies" class="text-sm text-orange-600 hover:text-orange-800 mb-4 inline-block">
      &larr; Back to Companies
    </router-link>

    <LoadingSpinner v-if="store.loading" />

    <template v-else-if="store.currentCompany">
      <div class="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <h1 class="text-2xl font-bold text-gray-900">{{ store.currentCompany.name }}</h1>
        <div class="mt-4 grid grid-cols-2 md:grid-cols-3 gap-4">
          <div>
            <p class="text-xs text-gray-500 uppercase">Domain</p>
            <p class="text-sm text-gray-900">{{ store.currentCompany.domain || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Industry</p>
            <p class="text-sm text-gray-900">{{ store.currentCompany.industry || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Phone</p>
            <p class="text-sm text-gray-900">{{ store.currentCompany.phone || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Location</p>
            <p class="text-sm text-gray-900">{{ [store.currentCompany.city, store.currentCompany.country].filter(Boolean).join(', ') || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Employees</p>
            <p class="text-sm text-gray-900">{{ store.currentCompany.number_of_employees || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Annual Revenue</p>
            <p class="text-sm text-gray-900">{{ store.currentCompany.annual_revenue ? formatCurrency(store.currentCompany.annual_revenue) : '-' }}</p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Associated Deals</h2>
          <div v-if="store.currentCompany.deals?.length" class="space-y-3">
            <router-link
              v-for="deal in store.currentCompany.deals"
              :key="deal.id"
              :to="{ name: 'deal', params: { id: deal.id } }"
              class="block p-3 border rounded-lg hover:bg-gray-50"
            >
              <div class="flex items-center justify-between">
                <p class="text-sm font-medium text-gray-900">{{ deal.name }}</p>
                <p class="text-sm font-semibold text-green-600">{{ deal.amount ? formatCurrency(deal.amount) : '-' }}</p>
              </div>
              <p class="text-xs text-gray-500">{{ deal.stage_name }}</p>
            </router-link>
          </div>
          <p v-else class="text-sm text-gray-500">No associated deals</p>
        </div>

        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Associated Contacts</h2>
          <div v-if="store.currentCompany.contacts?.length" class="space-y-3">
            <router-link
              v-for="contact in store.currentCompany.contacts"
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
      </div>
    </template>
  </div>
</template>

<script setup>
import { onMounted } from "vue"
import { useCompaniesStore } from "../stores/companies.js"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"

const props = defineProps({ id: { type: [String, Number], required: true } })
const store = useCompaniesStore()

onMounted(() => store.fetchCompany(props.id))

function formatCurrency(amount) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(amount)
}
</script>
