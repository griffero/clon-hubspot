require "json"

module Hubspot
  module Export
    class ReconciliationReport
      def initialize(run:, store:)
        @run = run
        @store = store
      end

      def as_json
        table_rows = run.export_tables.order(:extractor_key).map do |table|
          health = jsonl_health(table)
          actual_count = health[:line_count]

          {
            extractor_key: table.extractor_key,
            object_type: table.object_type,
            status: reconcile_status(table, actual_count, health),
            expected_count: table.expected_count,
            extracted_count: table.extracted_count,
            actual_count: actual_count,
            delta: actual_count - table.extracted_count,
            checksum_match: checksum_match?(table),
            endpoint: table.metadata["endpoint"],
            duplicate_record_ids: health[:duplicate_record_ids],
            invalid_json_lines: health[:invalid_json_lines],
            warnings: compact_warnings(table, actual_count, health)
          }
        end

        {
          run_id: run.run_id,
          portal_id: run.portal_id,
          generated_at: Time.current.iso8601,
          mismatch_count: table_rows.count { |r| r[:status] == "mismatch" },
          partial_count: table_rows.count { |r| r[:status] == "partial" },
          rows: table_rows
        }
      end

      private

      attr_reader :run, :store

      def checksum_match?(table)
        return true if table.checksum.blank?

        table.checksum == store.checksum(table.file_path)
      end

      def jsonl_health(table)
        return { line_count: table.extracted_count, duplicate_record_ids: 0, invalid_json_lines: 0 } unless table.file_path.end_with?(".jsonl")

        path = store.absolute_path(table.file_path)
        return { line_count: 0, duplicate_record_ids: 0, invalid_json_lines: 0 } unless File.exist?(path)

        line_count = 0
        invalid_json_lines = 0
        seen_ids = {}
        duplicate_record_ids = 0

        File.foreach(path) do |line|
          line_count += 1
          parsed = JSON.parse(line)
          record_id = parsed["_record_id"] || parsed["id"]
          next if record_id.blank?

          seen_ids[record_id] = seen_ids.fetch(record_id, 0) + 1
          duplicate_record_ids += 1 if seen_ids[record_id] > 1
        rescue JSON::ParserError
          invalid_json_lines += 1
        end

        {
          line_count: line_count,
          duplicate_record_ids: duplicate_record_ids,
          invalid_json_lines: invalid_json_lines
        }
      end

      def reconcile_status(table, actual_count, health)
        return "mismatch" unless checksum_match?(table)
        return "mismatch" if table.file_path.end_with?(".jsonl") && table.extracted_count != actual_count
        return "mismatch" if health[:invalid_json_lines].positive?
        return "partial" if table.extracted_count.to_i.zero?
        return "partial" if health[:duplicate_record_ids].positive?

        "ok"
      end

      def compact_warnings(table, actual_count, health)
        warnings = []
        warnings << "count mismatch" if table.extracted_count != actual_count && table.file_path.end_with?(".jsonl")
        warnings << "checksum mismatch" unless checksum_match?(table)
        warnings << "no records extracted" if table.extracted_count.to_i.zero?
        warnings << "duplicate record ids detected" if health[:duplicate_record_ids].positive?
        warnings << "invalid json lines detected" if health[:invalid_json_lines].positive?
        warnings
      end
    end
  end
end
