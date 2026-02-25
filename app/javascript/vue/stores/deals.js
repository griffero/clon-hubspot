import { defineStore } from "pinia"
import dealsApi from "../api/deals.js"

export const useDealsStore = defineStore("deals", {
  state: () => ({
    deals: [],
    kanbanData: null,
    currentDeal: null,
    pagination: null,
    loading: false,
    error: null,
  }),

  actions: {
    async fetchDeals(params = {}) {
      this.loading = true
      this.error = null
      try {
        const data = await dealsApi.list(params)
        this.deals = data.deals
        this.pagination = data.pagination
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    async fetchKanban(params = {}) {
      this.loading = true
      this.error = null
      try {
        this.kanbanData = await dealsApi.kanban(params)
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    async fetchDeal(id) {
      this.loading = true
      this.error = null
      try {
        const data = await dealsApi.get(id)
        this.currentDeal = data.deal
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },
  },
})
