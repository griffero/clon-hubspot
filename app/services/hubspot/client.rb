require_relative "errors"

module Hubspot
  class Client
    BASE_URL = "https://backend.composio.dev"
    DEFAULT_MAX_RETRIES = 5
    BASE_BACKOFF_SECONDS = 1.0
    MAX_BACKOFF_SECONDS = 30.0

    def self.default
      @default ||= new
    end

    def self.connection
      default.connection
    end

    def self.execute_action(action_name, input = {})
      default.execute_action(action_name, input)
    end

    attr_reader :connection

    def initialize(
      api_key: Hubspot::Configuration.composio_api_key,
      connected_account_id: Hubspot::Configuration.composio_connected_account_id,
      connection: nil
    )
      raise Hubspot::ConfigurationError, "Missing COMPOSIO_API_KEY" if api_key.blank?
      raise Hubspot::ConfigurationError, "Missing COMPOSIO_CONNECTED_ACCOUNT_ID" if connected_account_id.blank?

      @connected_account_id = connected_account_id
      @connection = connection || build_connection(api_key)
    end

    def execute_action(action_name, input = {}, max_retries: DEFAULT_MAX_RETRIES)
      with_retries(max_retries: max_retries) do
        response = do_request(action_name, input)
        parse_response!(response)
      end
    end

    private

    attr_reader :connected_account_id

    def build_connection(api_key)
      Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.headers["x-api-key"] = api_key
        f.options.timeout = 120
        f.options.open_timeout = 15
      end
    end

    def do_request(action_name, input)
      body = {
        connectedAccountId: connected_account_id,
        input: input
      }

      connection.post("/api/v2/actions/#{action_name}/execute", body)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise Hubspot::ApiError.new(e.message, status: nil)
    end

    def parse_response!(response)
      unless response.success?
        raise Hubspot::ApiError.new(
          "Composio API error #{response.status}",
          status: response.status,
          response_body: response.body,
          headers: response.headers
        )
      end

      parsed = response.body.is_a?(String) ? JSON.parse(response.body) : response.body
      parsed = parsed["data"].is_a?(String) ? JSON.parse(parsed["data"]) : parsed["data"]
      raise Hubspot::ApiError.new("Action failed: empty response body") if parsed.nil?

      parsed
    rescue JSON::ParserError => e
      raise Hubspot::ApiError.new("Failed to parse Composio response: #{e.message}", status: response&.status)
    end

    def with_retries(max_retries:)
      attempts = 0

      begin
        attempts += 1
        yield
      rescue Hubspot::ApiError => e
        raise unless should_retry?(error: e, attempts: attempts, max_retries: max_retries)

        sleep(backoff_seconds(attempts, retry_after: e.retry_after_seconds))
        retry
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      if attempts < max_retries
        sleep(backoff_seconds(attempts))
        retry
      end

      raise Hubspot::RetryExhaustedError, "Retry exhausted after #{attempts} attempts: #{e.message}"
    end

    def should_retry?(error:, attempts:, max_retries:)
      return false unless error.retriable?

      if attempts >= max_retries
        raise Hubspot::RetryExhaustedError,
              "Retry exhausted after #{attempts} attempts for status=#{error.status}: #{error.response_body}"
      end

      true
    end

    def backoff_seconds(attempts, retry_after: nil)
      return retry_after if retry_after.to_f.positive?

      exponential = [BASE_BACKOFF_SECONDS * (2**(attempts - 1)), MAX_BACKOFF_SECONDS].min
      jitter = rand * exponential * 0.2
      (exponential + jitter).round(3)
    end
  end
end
