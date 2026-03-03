module Hubspot
  module Export
    class Verifier
      def initialize(run:, store:)
        @run = run
        @store = store
      end

      def verify!
        mismatches = []

        run.export_tables.find_each do |table|
          file_exists = File.exist?(store.absolute_path(table.file_path))
          line_count = store.line_count(table.file_path)
          checksum = store.checksum(table.file_path)
          expected = table.extracted_count

          count_matches = if table.file_path.end_with?(".jsonl")
                            expected == line_count
                          else
                            true
                          end

          checksum_matches = table.checksum.blank? || table.checksum == checksum
          next if file_exists && count_matches && checksum_matches

          mismatches << {
            extractor_key: table.extractor_key,
            file_path: table.file_path,
            file_exists: file_exists,
            expected_count: expected,
            actual_count: line_count,
            expected_checksum: table.checksum,
            actual_checksum: checksum
          }
        end

        result = {
          run_id: run.run_id,
          checked_at: Time.current.iso8601,
          table_count: run.export_tables.count,
          mismatch_count: mismatches.count,
          mismatches: mismatches
        }

        store.write_json("manifests/verification_report.json", result)

        if mismatches.empty?
          run.export_tables.update_all(status: ExportTable.statuses.fetch("verified"))
        else
          mismatched_keys = mismatches.map { |row| row[:extractor_key] }
          run.export_tables.where(extractor_key: mismatched_keys).update_all(status: ExportTable.statuses.fetch("mismatch"))
        end

        result
      end

      def verify_passed?
        verify!.fetch(:mismatch_count).zero?
      end

      private

      attr_reader :run, :store
    end
  end
end
