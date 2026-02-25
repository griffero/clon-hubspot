import client from "./client.js"

export default {
  list() {
    return client.get("/api/v1/pipelines")
  },
  get(id) {
    return client.get(`/api/v1/pipelines/${id}`)
  },
}
