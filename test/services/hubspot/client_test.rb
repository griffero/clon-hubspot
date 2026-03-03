require "test_helper"

class Hubspot::ClientTest < ActiveSupport::TestCase
  Response = Struct.new(:status, :body, :headers) do
    def success?
      status.to_i.between?(200, 299)
    end
  end

  class SequenceConnection
    attr_reader :calls

    def initialize(responses)
      @responses = responses
      @calls = []
    end

    def post(path, body)
      @calls << { path: path, body: body }
      @responses.shift
    end
  end

  test "retries retriable status and succeeds" do
    responses = [
      Response.new(429, { "message" => "rate limited" }, {}),
      Response.new(200, { "data" => { "results" => [{ "id" => "1" }] } }, {})
    ]
    connection = SequenceConnection.new(responses)
    client = Hubspot::Client.new(api_key: "test", connected_account_id: "acc", connection: connection)

    sleeps = []
    client.define_singleton_method(:sleep) { |seconds| sleeps << seconds }
    client.define_singleton_method(:rand) { 0.0 }

    result = client.execute_action("ANY_ACTION", {}, max_retries: 3)

    assert_equal 1, result.fetch("results").size
    assert_equal 2, connection.calls.size
    assert_equal [1.0], sleeps
  end

  test "raises retry exhausted when retriable errors exceed max" do
    responses = Array.new(3) { Response.new(503, { "error" => "down" }, {}) }
    connection = SequenceConnection.new(responses)
    client = Hubspot::Client.new(api_key: "test", connected_account_id: "acc", connection: connection)

    retry_exhausted = Hubspot.const_get(:RetryExhaustedError)
    client.define_singleton_method(:sleep) { |_seconds| nil }
    client.define_singleton_method(:rand) { 0.0 }

    error = assert_raises(retry_exhausted) do
      client.execute_action("ANY_ACTION", {}, max_retries: 3)
    end

    assert_match(/Retry exhausted/, error.message)
    assert_equal 3, connection.calls.size
  end
end
