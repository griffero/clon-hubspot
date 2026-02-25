import { defineStore } from "pinia"
import companiesApi from "../api/companies.js"

export const useCompaniesStore = defineStore("companies", {
  state: () => ({
    companies: [],
    currentCompany: null,
    pagination: null,
    loading: false,
    error: null,
  }),

  actions: {
    async fetchCompanies(params = {}) {
      this.loading = true
      this.error = null
      try {
        const data = await companiesApi.list(params)
        this.companies = data.companies
        this.pagination = data.pagination
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    async fetchCompany(id) {
      this.loading = true
      this.error = null
      try {
        const data = await companiesApi.get(id)
        this.currentCompany = data.company
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },
  },
})
