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
    result = client.stub(:sleep, ->(seconds) { sleeps << seconds }) do
      client.stub(:rand, 0.0) do
        client.execute_action("ANY_ACTION", {}, max_retries: 3)
      end
    end

    assert_equal 1, result.fetch("results").size
    assert_equal 2, connection.calls.size
    assert_equal [1.0], sleeps
  end

  test "raises retry exhausted when retriable errors exceed max" do
    responses = Array.new(3) { Response.new(503, { "error" => "down" }, {}) }
    connection = SequenceConnection.new(responses)
    client = Hubspot::Client.new(api_key: "test", connected_account_id: "acc", connection: connection)

    error = assert_raises(Hubspot::RetryExhaustedError) do
      client.stub(:sleep, ->(_seconds) {}) do
        client.stub(:rand, 0.0) do
          client.execute_action("ANY_ACTION", {}, max_retries: 3)
        end
      end
    end

    assert_match(/Retry exhausted/, error.message)
    assert_equal 3, connection.calls.size
  end
end
