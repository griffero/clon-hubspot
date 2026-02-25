import client from "./client.js"

export default {
  list(params = {}) {
    return client.get("/api/v1/deals", params)
  },
  kanban(params = {}) {
    return client.get("/api/v1/deals", { view: "kanban", ...params })
  },
  get(id) {
    return client.get(`/api/v1/deals/${id}`)
  },
}
