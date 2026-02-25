function getCsrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta ? meta.getAttribute("content") : ""
}

async function request(url, options = {}) {
  const defaults = {
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": getCsrfToken(),
    },
  }

  const response = await fetch(url, { ...defaults, ...options })

  if (!response.ok) {
    const error = new Error(`API error: ${response.status}`)
    error.status = response.status
    throw error
  }

  return response.json()
}

export default {
  get(url, params = {}) {
    const query = new URLSearchParams(params).toString()
    const fullUrl = query ? `${url}?${query}` : url
    return request(fullUrl)
  },

  post(url, body = {}) {
    return request(url, {
      method: "POST",
      body: JSON.stringify(body),
    })
  },
}
