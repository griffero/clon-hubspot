require "test_helper"
require "fileutils"
require "securerandom"

class Hubspot::Export::VerifierTest < ActiveSupport::TestCase
  teardown do
    return unless defined?(@run) && @run

    FileUtils.rm_rf(Rails.root.join("exports", "run_id=#{@run.run_id}"))
  end

  test "marks tables verified when counts and checksums match" do
    @run = ExportRun.create!(run_id: "run-verify-#{SecureRandom.hex(4)}", portal_id: "p1", mode: :full, status: :running)
    store = Hubspot::Export::FileStore.new(@run)
    store.ensure_layout!

    relative_path = "raw_jsonl/object=contacts/part-00001.jsonl"
    store.append_jsonl(relative_path, [{ "id" => "1" }, { "id" => "2" }])

    checksum = store.checksum(relative_path)
    @run.export_tables.create!(
      extractor_key: "crm_contacts",
      object_type: "contacts",
      file_path: relative_path,
      extracted_count: 2,
      expected_count: 2,
      checksum: checksum,
      status: :written
    )

    result = Hubspot::Export::Verifier.new(run: @run, store: store).verify!

    assert_equal 0, result[:mismatch_count]
    assert_equal "verified", @run.export_tables.first.reload.status
    assert File.exist?(Rails.root.join("exports", "run_id=#{@run.run_id}", "manifests", "verification_report.json"))
  end

  test "flags mismatch when extracted count does not match file" do
    @run = ExportRun.create!(run_id: "run-mismatch-#{SecureRandom.hex(4)}", portal_id: "p1", mode: :full, status: :running)
    store = Hubspot::Export::FileStore.new(@run)
    store.ensure_layout!

    relative_path = "raw_jsonl/object=companies/part-00001.jsonl"
    store.append_jsonl(relative_path, [{ "id" => "1" }])

    @run.export_tables.create!(
      extractor_key: "crm_companies",
      object_type: "companies",
      file_path: relative_path,
      extracted_count: 2,
      expected_count: 2,
      checksum: store.checksum(relative_path),
      status: :written
    )

    result = Hubspot::Export::Verifier.new(run: @run, store: store).verify!

    assert_equal 1, result[:mismatch_count]
    assert_equal "mismatch", @run.export_tables.first.reload.status
  end
end
