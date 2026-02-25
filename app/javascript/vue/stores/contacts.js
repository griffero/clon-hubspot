import { defineStore } from "pinia"
import contactsApi from "../api/contacts.js"

export const useContactsStore = defineStore("contacts", {
  state: () => ({
    contacts: [],
    currentContact: null,
    pagination: null,
    loading: false,
    error: null,
  }),

  actions: {
    async fetchContacts(params = {}) {
      this.loading = true
      this.error = null
      try {
        const data = await contactsApi.list(params)
        this.contacts = data.contacts
        this.pagination = data.pagination
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },

    async fetchContact(id) {
      this.loading = true
      this.error = null
      try {
        const data = await contactsApi.get(id)
        this.currentContact = data.contact
      } catch (e) {
        this.error = e.message
      } finally {
        this.loading = false
      }
    },
  },
})
