<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Companies</h1>
      <div class="w-80">
        <SearchInput v-model="searchQuery" placeholder="Search companies..." @update:modelValue="onSearch" />
      </div>
    </div>

    <LoadingSpinner v-if="store.loading" />

    <template v-else>
      <EmptyState v-if="store.companies.length === 0" title="No companies" message="No companies found." />

      <div v-else class="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Domain</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Industry</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Employees</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Revenue</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="company in store.companies" :key="company.id" class="hover:bg-gray-50">
              <td class="px-6 py-4">
                <router-link :to="{ name: 'company', params: { id: company.id } }" class="text-sm font-medium text-orange-600 hover:text-orange-800">
                  {{ company.name || '-' }}
                </router-link>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ company.domain || '-' }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ company.industry || '-' }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ company.number_of_employees || '-' }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ company.annual_revenue ? formatCurrency(company.annual_revenue) : '-' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <Pagination :pagination="store.pagination" @page-change="(p) => loadData(p)" />
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue"
import { useCompaniesStore } from "../stores/companies.js"
import SearchInput from "../components/shared/SearchInput.vue"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"
import EmptyState from "../components/shared/EmptyState.vue"
import Pagination from "../components/shared/Pagination.vue"

const store = useCompaniesStore()
const searchQuery = ref("")
let searchTimeout = null

onMounted(() => loadData())

function loadData(page = 1) {
  store.fetchCompanies({ page, q: searchQuery.value || undefined })
}

function onSearch() {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => loadData(), 300)
}

function formatCurrency(amount) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(amount)
}
</script>
