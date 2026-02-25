module Hubspot
  class Client
    BASE_URL = "https://backend.composio.dev"

    def self.connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.request :retry, {
          max: 3,
          interval: 2,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503]
        }
        f.headers["x-api-key"] = ENV.fetch("COMPOSIO_API_KEY")
        f.options.timeout = 120
        f.options.open_timeout = 15
      end
    end

    def self.execute_action(action_name, input = {})
      body = {
        connectedAccountId: ENV.fetch("COMPOSIO_CONNECTED_ACCOUNT_ID"),
        input: input
      }

      response = connection.post("/api/v2/actions/#{action_name}/execute", body)
      raise "Composio API error #{response.status}: #{response.body}" unless response.success?

      parsed = response.body.is_a?(String) ? JSON.parse(response.body) : response.body

      # Composio sometimes double-encodes the response
      if parsed["data"].is_a?(String)
        parsed = JSON.parse(parsed["data"]) rescue parsed["data"]
      else
        parsed = parsed["data"]
      end

      raise "Action failed: #{parsed}" if parsed.nil?

      parsed
    end
  end
end
