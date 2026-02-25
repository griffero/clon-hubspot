import { defineStore } from "pinia"
import pipelinesApi from "../api/pipelines.js"

export const usePipelinesStore = defineStore("pipelines", {
  state: () => ({
    pipelines: [],
    currentPipeline: null,
    loading: false,
    error: null,
  }),

  actions: {
    async fetchPipelines() {
      this.loading = true
      this.error = null
      try {
        const data = await pipelinesApi.list()
        this.pipelines = data.pipelines
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    async fetchPipeline(id) {
      this.loading = true
      this.error = null
      try {
        const data = await pipelinesApi.get(id)
        this.currentPipeline = data.pipeline
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },
  },
})
