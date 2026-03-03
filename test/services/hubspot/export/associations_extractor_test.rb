require "test_helper"
require "fileutils"
require "securerandom"

class Hubspot::Export::AssociationsExtractorTest < ActiveSupport::TestCase
  class FakeClient
    def initialize
      @calls = 0
    end

    def execute_action(_action, _payload)
      @calls += 1
      {
        "results" => [
          {
            "from" => { "id" => "1" },
            "to" => [ { "id" => "99", "label" => "primary" } ]
          }
        ]
      }
    end
  end

  teardown do
    return unless defined?(@run) && @run

    FileUtils.rm_rf(Rails.root.join("exports", "run_id=#{@run.run_id}"))
  end

  test "exports associations from source object records" do
    @run = ExportRun.create!(run_id: "run-assoc-#{SecureRandom.hex(4)}", portal_id: "p1", mode: :full, status: :running)
    store = Hubspot::Export::FileStore.new(@run)
    store.ensure_layout!

    store.append_jsonl("raw_jsonl/object=contacts/part-00001.jsonl", [
      { "_record_id" => "1" },
      { "_record_id" => "2" }
    ])

    extractor = Hubspot::Export::AssociationsExtractor.new(
      run: @run,
      portal_id: "p1",
      store: store,
      client: FakeClient.new,
      source_object: "contacts",
      target_objects: [ "companies" ]
    )

    extractor.call

    table = @run.export_tables.find_by!(extractor_key: "assoc_contacts")
    assert_equal "contacts_associations", table.object_type
    assert_equal 1, table.extracted_count
    assert_equal 1, store.line_count("raw_jsonl/object=contacts_associations/part-00001.jsonl")
  end
end
