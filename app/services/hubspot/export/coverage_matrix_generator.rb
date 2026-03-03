module Hubspot
  module Export
    class CoverageMatrixGenerator
      def initialize(run:)
        @run = run
      end

      def as_json
        rows = Constants.object_extractors.map do |config|
          table = run.export_tables.find { |t| t.extractor_key == config.fetch(:extractor_key) }
          {
            domain: "crm",
            object_type: config.fetch(:object_type),
            extractor_key: config.fetch(:extractor_key),
            endpoint: table&.metadata&.dig("endpoint"),
            fields_included: config.fetch(:properties),
            history_available: false,
            associations_available: run.export_tables.any? { |t| t.object_type == "#{config.fetch(:object_type)}_associations" },
            deletion_signal_available: deletion_signal_available?(table),
            schema_drift_detected: schema_drift_detected?(table),
            status: coverage_status_for(table),
            blocker_reason: blocker_for(table),
            next_action: next_action_for(table)
          }
        end

        {
          generated_at: Time.current.iso8601,
          run_id: run.run_id,
          portal_id: run.portal_id,
          rows: rows
        }
      end

      def as_markdown
        json = as_json
        lines = []
        lines << "# HubSpot Coverage Matrix"
        lines << ""
        lines << "- Run ID: #{json[:run_id]}"
        lines << "- Generated At: #{json[:generated_at]}"
        lines << ""
        lines << "| Object | Status | Associations | Deletion | Schema Drift | Endpoint | Blocker |"
        lines << "|---|---|---|---|---|---|---|"
        json[:rows].each do |row|
          lines << "| #{row[:object_type]} | #{row[:status]} | #{yes_no(row[:associations_available])} | #{yes_no(row[:deletion_signal_available])} | #{yes_no(row[:schema_drift_detected])} | #{row[:endpoint] || '-'} | #{row[:blocker_reason] || '-'} |"
        end
        lines << ""
        lines.join("\n")
      end

      private

      attr_reader :run

      def coverage_status_for(table)
        return "BLOCKED" if table.nil?
        return "PARTIAL" if table.extracted_count.to_i.zero?

        "FULL"
      end

      def blocker_for(table)
        return "Extractor not executed" if table.nil?
        return "No records extracted in current run" if table.extracted_count.to_i.zero?

        nil
      end

      def next_action_for(table)
        return "Check extractor wiring and Composio action availability" if table.nil?
        return "Validate endpoint filters/permissions; inspect checkpoint errors" if table.extracted_count.to_i.zero?

        drift = table.metadata.dig("schema_drift", "unexpected_count").to_i + table.metadata.dig("schema_drift", "missing_count").to_i
        return "Review schema drift and update property metadata snapshots" if drift.positive?

        "None"
      end

      def deletion_signal_available?(table)
        table&.metadata&.dig("deletion_strategy", "flags").present?
      end

      def schema_drift_detected?(table)
        return false if table.nil?

        table.metadata.dig("schema_drift", "unexpected_count").to_i.positive? ||
          table.metadata.dig("schema_drift", "missing_count").to_i.positive?
      end

      def yes_no(value)
        value ? "yes" : "no"
      end
    end
  end
end
