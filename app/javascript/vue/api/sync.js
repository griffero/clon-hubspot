import client from "./client.js"

export default {
  trigger() {
    return client.post("/api/v1/sync")
  },
}
