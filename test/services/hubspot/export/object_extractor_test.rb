require "test_helper"
require "fileutils"
require "securerandom"

class Hubspot::Export::ObjectExtractorTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :requests

    def initialize(responses)
      @responses = responses
      @requests = []
    end

    def execute_action(action, payload)
      @requests << { action: action, payload: payload }
      @responses.shift || { "results" => [] }
    end
  end

  teardown do
    return unless defined?(@run) && @run

    FileUtils.rm_rf(Rails.root.join("exports", "run_id=#{@run.run_id}"))
  end

  test "resumes from checkpoint cursor and appends rows" do
    @run = ExportRun.create!(run_id: "run-resume-#{SecureRandom.hex(4)}", portal_id: "p1", mode: :full, status: :running)
    store = Hubspot::Export::FileStore.new(@run)
    store.ensure_layout!

    relative_path = "raw_jsonl/object=contacts/part-00001.jsonl"
    store.append_jsonl(relative_path, [{ "_record_id" => "existing" }])

    checkpoint = ExportCheckpoint.create!(
      export_run: @run,
      portal_id: "p1",
      extractor_key: "crm_contacts",
      status: :running,
      cursor: "next-cursor",
      records_exported: 1
    )

    client = FakeClient.new([
      {
        "results" => [{ "id" => "2", "properties" => { "email" => "a@example.com" } }],
        "paging" => {}
      }
    ])

    config = Hubspot::Export::Constants.object_extractors.find { |c| c[:extractor_key] == "crm_contacts" }
    extractor = Hubspot::Export::ObjectExtractor.new(
      run: @run,
      portal_id: "p1",
      store: store,
      client: client,
      config: config,
      incremental_since: nil
    )

    extractor.call

    checkpoint.reload
    assert checkpoint.succeeded?
    assert_equal 2, checkpoint.records_exported
    assert_equal "next-cursor", client.requests.first[:payload][:after]
    assert_equal 2, store.line_count(relative_path)

    table = @run.export_tables.find_by!(extractor_key: "crm_contacts")
    assert_equal 2, table.extracted_count
    assert_equal "raw_jsonl/object=contacts/part-00001.jsonl", table.file_path
    assert_equal [], table.metadata.dig("schema_drift", "unexpected_properties")
    assert_includes table.metadata.dig("deletion_strategy", "flags"), "record.archived"
  end
end
