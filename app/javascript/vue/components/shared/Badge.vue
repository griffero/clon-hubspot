<template>
  <span
    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    :class="colorClasses"
  >
    <slot />
  </span>
</template>

<script setup>
import { computed } from "vue"

const props = defineProps({
  color: { type: String, default: "gray" },
})

const colorMap = {
  gray: "bg-gray-100 text-gray-800",
  green: "bg-green-100 text-green-800",
  blue: "bg-blue-100 text-blue-800",
  orange: "bg-orange-100 text-orange-800",
  red: "bg-red-100 text-red-800",
  purple: "bg-purple-100 text-purple-800",
}

const colorClasses = computed(() => colorMap[props.color] || colorMap.gray)
</script>
