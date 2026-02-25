import client from "./client.js"

export default {
  list(params = {}) {
    return client.get("/api/v1/contacts", params)
  },
  get(id) {
    return client.get(`/api/v1/contacts/${id}`)
  },
}
