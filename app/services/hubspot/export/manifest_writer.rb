module Hubspot
  module Export
    class ManifestWriter
      def initialize(run:, store:)
        @run = run
        @store = store
      end

      def write!
        store.ensure_layout!
        tables = run.export_tables.order(:extractor_key)

        run_manifest = {
          run_id: run.run_id,
          portal_id: run.portal_id,
          mode: run.mode,
          status: run.status,
          started_at: run.started_at,
          finished_at: run.finished_at,
          api: {
            provider: "composio",
            connected_account_id: Hubspot::Configuration.composio_connected_account_id
          },
          totals: {
            tables: tables.count,
            records: tables.sum(:extracted_count)
          },
          stats: run.stats
        }

        tables_manifest = tables.map do |table|
          {
            extractor_key: table.extractor_key,
            object_type: table.object_type,
            file_path: table.file_path,
            expected_count: table.expected_count,
            extracted_count: table.extracted_count,
            checksum: table.checksum,
            status: table.status,
            metadata: table.metadata
          }
        end

        checksum_manifest = tables.each_with_object({}) do |table, memo|
          memo[table.file_path] = table.checksum
        end

        store.write_json("manifests/run_manifest.json", run_manifest)
        store.write_json("manifests/tables_manifest.json", tables_manifest)
        store.write_json("manifests/checksum_manifest.json", checksum_manifest)
        store.write_json("manifests/run_report.json", build_run_report(tables_manifest))
        store.write_text("manifests/run_report.md", build_run_report_markdown(tables_manifest))
      end

      private

      attr_reader :run, :store

      def build_run_report(tables_manifest)
        {
          run_id: run.run_id,
          generated_at: Time.current.iso8601,
          verification_ready: tables_manifest.all? { |row| row[:status] == "written" || row[:status] == "verified" },
          table_summaries: tables_manifest.map do |row|
            {
              extractor_key: row[:extractor_key],
              object_type: row[:object_type],
              extracted_count: row[:extracted_count],
              status: row[:status]
            }
          end
        }
      end

      def build_run_report_markdown(tables_manifest)
        lines = []
        lines << "# HubSpot Export Run Report"
        lines << ""
        lines << "- Run ID: #{run.run_id}"
        lines << "- Portal ID: #{run.portal_id}"
        lines << "- Mode: #{run.mode}"
        lines << "- Status: #{run.status}"
        lines << "- Started At: #{run.started_at}"
        lines << "- Finished At: #{run.finished_at}"
        lines << ""
        lines << "## Tables"
        lines << ""
        lines << "| Extractor | Object | Count | Status |"
        lines << "|---|---|---:|---|"
        tables_manifest.each do |row|
          lines << "| #{row[:extractor_key]} | #{row[:object_type]} | #{row[:extracted_count]} | #{row[:status]} |"
        end
        lines << ""
        lines.join("\n")
      end
    end
  end
end
