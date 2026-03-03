require "digest"

module Hubspot
  module Export
    class ObjectExtractor
      PAGE_SIZE = 100

      def initialize(run:, portal_id:, store:, client:, config:, incremental_since: nil)
        @run = run
        @portal_id = portal_id
        @store = store
        @client = client
        @config = config
        @incremental_since = incremental_since
      end

      def call
        checkpoint = CheckpointStore.fetch_or_create!(run: run, portal_id: portal_id, extractor_key: config.fetch(:extractor_key))
        return checkpoint if checkpoint.succeeded?

        checkpoint.mark_running!

        cursor = checkpoint.cursor
        extracted_count = checkpoint.records_exported
        file_path = "raw_jsonl/object=#{config.fetch(:object_type)}/part-00001.jsonl"
        highest_seen = checkpoint.high_watermark

        loop do
          payload = build_payload(cursor)
          response = client.execute_action(resolve_action, payload)
          results = response["results"] || []
          extracted_at = Time.current.iso8601

          rows = results.map do |record|
            props = record["properties"] || {}
            last_modified = parse_time(props["hs_lastmodifieddate"])
            highest_seen = [highest_seen, last_modified].compact.max

            {
              **base_columns(record, extracted_at, cursor),
              "properties" => props,
              "associations" => record["associations"] || {}
            }
          end

          store.append_jsonl(file_path, rows)

          extracted_count += results.length
          next_cursor = response.dig("paging", "next", "after")

          checkpoint.update!(
            cursor: next_cursor,
            records_exported: extracted_count,
            high_watermark: highest_seen,
            metadata: checkpoint.metadata.merge("last_page_count" => results.length)
          )
          run.heartbeat!

          break if next_cursor.blank? || results.empty?
          cursor = next_cursor
        end

        checksum = store.checksum(file_path)
        upsert_table_record!(file_path: file_path, extracted_count: extracted_count, checksum: checksum)
        checkpoint.mark_succeeded!(high_watermark: highest_seen)
        checkpoint
      rescue Hubspot::RetryExhaustedError => e
        checkpoint.mark_retry_exhausted!(e.message)
        raise
      rescue StandardError => e
        checkpoint.mark_failed!(e.message)
        raise
      end

      private

      attr_reader :run, :portal_id, :store, :client, :config, :incremental_since

      def resolve_action
        incremental_since.present? ? config.fetch(:search_action) : config.fetch(:list_action)
      end

      def build_payload(cursor)
        payload = {
          limit: PAGE_SIZE,
          properties: config.fetch(:properties)
        }
        payload[:after] = cursor if cursor.present?

        return payload if incremental_since.blank?

        payload[:filterGroups] = [
          {
            filters: [
              {
                propertyName: "hs_lastmodifieddate",
                operator: "GTE",
                value: (incremental_since.to_f * 1000).to_i.to_s
              }
            ]
          }
        ]
        payload
      end

      def base_columns(record, extracted_at, cursor)
        raw_hash = Digest::SHA256.hexdigest(JSON.generate(record))

        {
          "_hs_portal_id" => portal_id,
          "_object_type" => config.fetch(:object_type),
          "_record_id" => record["id"],
          "_extracted_at" => extracted_at,
          "_cursor" => cursor,
          "_source_endpoint" => resolve_action,
          "_run_id" => run.run_id,
          "_raw_hash" => raw_hash,
          "_deleted" => false,
          "_valid_from" => nil,
          "_valid_to" => nil
        }
      end

      def upsert_table_record!(file_path:, extracted_count:, checksum:)
        table = run.export_tables.find_or_initialize_by(extractor_key: config.fetch(:extractor_key))
        table.update!(
          object_type: config.fetch(:object_type),
          file_path: file_path,
          expected_count: extracted_count,
          extracted_count: extracted_count,
          checksum: checksum,
          status: :written,
          metadata: {
            endpoint: resolve_action,
            base_columns: Constants.base_columns
          }
        )
      end

      def parse_time(value)
        return nil if value.blank?
        return Time.zone.at(value.to_i / 1000.0) if value.to_s.match?(/\A\d+\z/)

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
