<template>
  <router-link
    :to="{ name: 'deal', params: { id: deal.id } }"
    class="block bg-white rounded-lg border border-gray-200 p-3 shadow-sm hover:shadow-md transition-shadow cursor-pointer"
  >
    <h4 class="text-sm font-medium text-gray-900 truncate">{{ deal.name }}</h4>
    <p v-if="deal.amount" class="mt-1 text-sm font-semibold text-green-600">
      {{ formatCurrency(deal.amount) }}
    </p>
    <p v-if="deal.close_date" class="mt-1 text-xs text-gray-500">
      Close: {{ formatDate(deal.close_date) }}
    </p>
  </router-link>
</template>

<script setup>
defineProps({
  deal: { type: Object, required: true },
})

function formatCurrency(amount) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount)
}

function formatDate(date) {
  return new Date(date).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
}
</script>
