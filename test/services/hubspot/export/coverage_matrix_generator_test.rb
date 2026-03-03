require "test_helper"

class Hubspot::Export::CoverageMatrixGeneratorTest < ActiveSupport::TestCase
  test "marks missing extractors as blocked" do
    run = ExportRun.create!(run_id: "run-cov-1", portal_id: "p1", mode: :full, status: :running)

    payload = Hubspot::Export::CoverageMatrixGenerator.new(run: run).as_json
    row = payload[:rows].find { |r| r[:object_type] == "contacts" }

    assert_equal "BLOCKED", row[:status]
  end
end
