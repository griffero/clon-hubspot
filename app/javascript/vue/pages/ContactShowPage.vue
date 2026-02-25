<template>
  <div>
    <router-link to="/contacts" class="text-sm text-orange-600 hover:text-orange-800 mb-4 inline-block">
      &larr; Back to Contacts
    </router-link>

    <LoadingSpinner v-if="store.loading" />

    <template v-else-if="store.currentContact">
      <div class="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <h1 class="text-2xl font-bold text-gray-900">{{ store.currentContact.full_name }}</h1>
        <div class="mt-4 grid grid-cols-2 md:grid-cols-3 gap-4">
          <div>
            <p class="text-xs text-gray-500 uppercase">Email</p>
            <p class="text-sm text-gray-900">{{ store.currentContact.email || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Phone</p>
            <p class="text-sm text-gray-900">{{ store.currentContact.phone || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Company</p>
            <p class="text-sm text-gray-900">{{ store.currentContact.company_name || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Job Title</p>
            <p class="text-sm text-gray-900">{{ store.currentContact.job_title || '-' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-500 uppercase">Lifecycle Stage</p>
            <Badge v-if="store.currentContact.lifecycle_stage" color="blue">{{ store.currentContact.lifecycle_stage }}</Badge>
            <span v-else class="text-sm text-gray-400">-</span>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Associated Deals</h2>
        <div v-if="store.currentContact.deals?.length" class="space-y-3">
          <router-link
            v-for="deal in store.currentContact.deals"
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
    </template>
  </div>
</template>

<script setup>
import { onMounted } from "vue"
import { useContactsStore } from "../stores/contacts.js"
import LoadingSpinner from "../components/shared/LoadingSpinner.vue"
import Badge from "../components/shared/Badge.vue"

const props = defineProps({ id: { type: [String, Number], required: true } })
const store = useContactsStore()

onMounted(() => store.fetchContact(props.id))

function formatCurrency(amount) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount)
}
</script>
