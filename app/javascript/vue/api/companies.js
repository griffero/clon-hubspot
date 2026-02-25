import client from "./client.js"

export default {
  list(params = {}) {
    return client.get("/api/v1/companies", params)
  },
  get(id) {
    return client.get(`/api/v1/companies/${id}`)
  },
}
