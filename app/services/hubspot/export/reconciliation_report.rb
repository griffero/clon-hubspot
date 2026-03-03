module Hubspot
  module Export
    class ReconciliationReport
      def initialize(run:, store:)
        @run = run
        @store = store
      end

      def as_json
        table_rows = run.export_tables.order(:extractor_key).map do |table|
          actual_count = table.file_path.end_with?(".jsonl") ? store.line_count(table.file_path) : table.extracted_count
          {
            extractor_key: table.extractor_key,
            object_type: table.object_type,
            status: reconcile_status(table, actual_count),
            expected_count: table.expected_count,
            extracted_count: table.extracted_count,
            actual_count: actual_count,
            delta: actual_count - table.extracted_count,
            checksum_match: checksum_match?(table),
            endpoint: table.metadata["endpoint"],
            warnings: compact_warnings(table, actual_count)
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

      def reconcile_status(table, actual_count)
        return "mismatch" unless checksum_match?(table)
        return "mismatch" if table.file_path.end_with?(".jsonl") && table.extracted_count != actual_count
        return "partial" if table.extracted_count.to_i.zero?

        "ok"
      end

      def compact_warnings(table, actual_count)
        warnings = []
        warnings << "count mismatch" if table.extracted_count != actual_count && table.file_path.end_with?(".jsonl")
        warnings << "checksum mismatch" unless checksum_match?(table)
        warnings << "no records extracted" if table.extracted_count.to_i.zero?
        warnings
      end
    end
  end
end
