require "test_helper"
require "fileutils"
require "securerandom"

class Hubspot::Export::ReconciliationReportTest < ActiveSupport::TestCase
  teardown do
    return unless defined?(@run) && @run

    FileUtils.rm_rf(Rails.root.join("exports", "run_id=#{@run.run_id}"))
  end

  test "marks table partial when duplicate record ids are detected" do
    @run = ExportRun.create!(run_id: "run-recon-dup-#{SecureRandom.hex(4)}", portal_id: "p1", mode: :full, status: :running)
    store = Hubspot::Export::FileStore.new(@run)
    store.ensure_layout!

    relative_path = "raw_jsonl/object=contacts/part-00001.jsonl"
    store.append_jsonl(relative_path, [{ "_record_id" => "1" }, { "_record_id" => "1" }])

    @run.export_tables.create!(
      extractor_key: "crm_contacts",
      object_type: "contacts",
      file_path: relative_path,
      extracted_count: 2,
      expected_count: 2,
      checksum: store.checksum(relative_path),
      status: :written
    )

    report = Hubspot::Export::ReconciliationReport.new(run: @run, store: store).as_json
    row = report[:rows].first

    assert_equal "partial", row[:status]
    assert_equal 1, row[:duplicate_record_ids]
  end
end
