<template>
  <header class="bg-white border-b border-gray-200 px-6 py-3 flex items-center justify-between">
    <div></div>
    <div class="flex items-center gap-4">
      <span v-if="syncMessage" class="text-sm text-green-600">{{ syncMessage }}</span>
      <button
        @click="triggerSync"
        :disabled="syncing"
        class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg transition-colors"
        :class="syncing
          ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
          : 'bg-orange-600 text-white hover:bg-orange-700'"
      >
        <ArrowPathIcon class="w-4 h-4" :class="{ 'animate-spin': syncing }" />
        {{ syncing ? "Syncing..." : "Sync Data" }}
      </button>
    </div>
  </header>
</template>

<script setup>
import { ref } from "vue"
import { ArrowPathIcon } from "@heroicons/vue/24/outline"
import syncApi from "../../api/sync.js"

const syncing = ref(false)
const syncMessage = ref("")

async function triggerSync() {
  syncing.value = true
  syncMessage.value = ""
  try {
    await syncApi.trigger()
    syncMessage.value = "Sync started! Data will update shortly."
    setTimeout(() => { syncMessage.value = "" }, 5000)
  } catch (e) {
    syncMessage.value = "Sync failed. Please try again."
  } finally {
    syncing.value = false
  }
}
</script>
