import { createRouter, createWebHistory } from "vue-router"

import DashboardPage from "./pages/DashboardPage.vue"
import DealsPage from "./pages/DealsPage.vue"
import DealShowPage from "./pages/DealShowPage.vue"
import ContactsPage from "./pages/ContactsPage.vue"
import ContactShowPage from "./pages/ContactShowPage.vue"
import CompaniesPage from "./pages/CompaniesPage.vue"
import CompanyShowPage from "./pages/CompanyShowPage.vue"
import PipelinesPage from "./pages/PipelinesPage.vue"

const routes = [
  { path: "/", name: "dashboard", component: DashboardPage },
  { path: "/deals", name: "deals", component: DealsPage },
  { path: "/deals/:id", name: "deal", component: DealShowPage, props: true },
  { path: "/contacts", name: "contacts", component: ContactsPage },
  { path: "/contacts/:id", name: "contact", component: ContactShowPage, props: true },
  { path: "/companies", name: "companies", component: CompaniesPage },
  { path: "/companies/:id", name: "company", component: CompanyShowPage, props: true },
  { path: "/pipelines", name: "pipelines", component: PipelinesPage },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
