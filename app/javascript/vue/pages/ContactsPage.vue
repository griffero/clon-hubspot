<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Contacts</h1>
      <div class="w-80">
        <SearchInput v-model="searchQuery" placeholder="Search contacts..." @update:modelValue="onSearch" />
      </div>
    </div>

    <LoadingSpinner v-if="store.loading" />

    <template v-else>
      <EmptyState v-if="store.contacts.length === 0" title="No contacts" message="No contacts found." />

      <div v-else class="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Phone</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Company</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Lifecycle Stage</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="contact in store.contacts" :key="contact.id" class="hover:bg-gray-50">
              <td class="px-6 py-4">
                <router-link :to="{ name: 'contact', params: { id: contact.id } }" class="text-sm font-medium text-orange-600 hover:text-orange-800">
                  {{ contact.full_name || '-' }}
                </router-link>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ contact.email || '-' }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ contact.phone || '-' }}</td>
              <td class="px-6 py-4 text-sm text-gray-500">{{ contact.company_name || '-' }}</td>
              <td class="px-6 py-4">
                <Badge v-if="contact.lifecycle_stage" color="blue">{{ contact.lifecycle_stage }}</Badge>
                <span v-else class="text-sm text-gray-400">-</span>
              </td>
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
import { useContactsStore } from "../stores/contacts.js"
import SearchInput from "../components/shared/SearchInput.vue"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"
import EmptyState from "../components/shared/EmptyState.vue"
import Pagination from "../components/shared/Pagination.vue"
import Badge from "../components/shared/Badge.vue"

const store = useContactsStore()
const searchQuery = ref("")
let searchTimeout = null

onMounted(() => loadData())

function loadData(page = 1) {
  store.fetchContacts({ page, q: searchQuery.value || undefined })
}

function onSearch() {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => loadData(), 300)
}
</script>
