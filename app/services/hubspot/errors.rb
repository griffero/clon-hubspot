module Hubspot
  class ConfigurationError < StandardError; end

  class ApiError < StandardError
    attr_reader :status, :response_body, :headers

    def initialize(message, status: nil, response_body: nil, headers: {})
      super(message)
      @status = status
      @response_body = response_body
      @headers = headers || {}
    end

    def retriable?
      [429, 500, 502, 503, 504].include?(status)
    end

    def retry_after_seconds
      value = headers["retry-after"] || headers["Retry-After"]
      return nil if value.blank?

      value.to_f
    rescue ArgumentError, TypeError
      nil
    end
  end

  class RetryExhaustedError < StandardError; end
end
