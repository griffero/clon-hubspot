<template>
  <aside class="w-64 bg-gray-900 text-white flex flex-col">
    <div class="p-4 border-b border-gray-700">
      <h1 class="text-xl font-bold tracking-tight">HubSpot CRM</h1>
      <p class="text-xs text-gray-400 mt-1">Clone</p>
    </div>
    <nav class="flex-1 p-3 space-y-1">
      <router-link
        v-for="item in navItems"
        :key="item.to"
        :to="item.to"
        class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
        :class="isActive(item.to) ? 'bg-orange-600 text-white' : 'text-gray-300 hover:bg-gray-800 hover:text-white'"
      >
        <component :is="item.icon" class="w-5 h-5" />
        {{ item.label }}
      </router-link>
    </nav>
  </aside>
</template>

<script setup>
import { useRoute } from "vue-router"
import {
  HomeIcon,
  CurrencyDollarIcon,
  UsersIcon,
  BuildingOfficeIcon,
  FunnelIcon,
} from "@heroicons/vue/24/outline"

const route = useRoute()

const navItems = [
  { to: "/", label: "Dashboard", icon: HomeIcon },
  { to: "/deals", label: "Deals", icon: CurrencyDollarIcon },
  { to: "/contacts", label: "Contacts", icon: UsersIcon },
  { to: "/companies", label: "Companies", icon: BuildingOfficeIcon },
  { to: "/pipelines", label: "Pipelines", icon: FunnelIcon },
]

function isActive(path) {
  if (path === "/") return route.path === "/"
  return route.path.startsWith(path)
}
</script>
