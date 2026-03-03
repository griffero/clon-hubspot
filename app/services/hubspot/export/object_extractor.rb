require "digest"
require "set"

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
        tombstone_count = checkpoint.metadata.fetch("tombstone_count", 0)
        observed_properties = Set.new(checkpoint.metadata.fetch("observed_properties", []))
        resolved_action = checkpoint.metadata["resolved_action"]

        loop do
          payload = build_payload(cursor)
          response, resolved_action = fetch_page(payload, resolved_action)
          results = response["results"] || []
          extracted_at = Time.current.iso8601

          rows = results.map do |record|
            props = record["properties"] || {}
            props.keys.each { |key| observed_properties << key }

            last_modified = parse_time(props["hs_lastmodifieddate"])
            highest_seen = [highest_seen, last_modified].compact.max
            deleted = record["archived"] == true || record["isDeleted"] == true
            tombstone_count += 1 if deleted

            {
              **base_columns(record, extracted_at, cursor, resolved_action, deleted),
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
            metadata: checkpoint.metadata.merge(
              "last_page_count" => results.length,
              "resolved_action" => resolved_action,
              "tombstone_count" => tombstone_count,
              "observed_properties" => observed_properties.to_a.sort
            )
          )
          run.heartbeat!

          break if next_cursor.blank? || results.empty?
          cursor = next_cursor
        end

        checksum = store.checksum(file_path)
        upsert_table_record!(
          file_path: file_path,
          extracted_count: extracted_count,
          checksum: checksum,
          endpoint: resolved_action,
          tombstone_count: tombstone_count,
          observed_properties: observed_properties.to_a.sort
        )
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

      def action_candidates
        if incremental_since.present?
          config.fetch(:search_action_candidates)
        else
          config.fetch(:list_action_candidates)
        end
      end

      def build_payload(cursor)
        payload = {
          limit: PAGE_SIZE,
          properties: config.fetch(:properties)
        }
        payload[:after] = cursor if cursor.present?

        if config[:custom_object_name].present? || config[:custom_object_id].present?
          payload[:objectType] = config[:custom_object_name] || config[:custom_object_id]
        end

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

      def fetch_page(payload, preferred_action = nil)
        candidates = [ preferred_action, *action_candidates ].compact.uniq
        last_error = nil

        candidates.each do |action|
          return [ client.execute_action(action, payload), action ]
        rescue StandardError => e
          last_error = e
        end

        raise(last_error || "No object extraction action candidates succeeded")
      end

      def base_columns(record, extracted_at, cursor, endpoint, deleted)
        raw_hash = Digest::SHA256.hexdigest(JSON.generate(record))

        {
          "_hs_portal_id" => portal_id,
          "_object_type" => config.fetch(:object_type),
          "_record_id" => record["id"],
          "_extracted_at" => extracted_at,
          "_cursor" => cursor,
          "_source_endpoint" => endpoint,
          "_run_id" => run.run_id,
          "_raw_hash" => raw_hash,
          "_deleted" => deleted,
          "_valid_from" => nil,
          "_valid_to" => nil
        }
      end

      def upsert_table_record!(file_path:, extracted_count:, checksum:, endpoint:, tombstone_count:, observed_properties:)
        requested_properties = config.fetch(:properties).map(&:to_s)
        unexpected_properties = observed_properties - requested_properties
        missing_requested_properties = requested_properties - observed_properties

        table = run.export_tables.find_or_initialize_by(extractor_key: config.fetch(:extractor_key))
        table.update!(
          object_type: config.fetch(:object_type),
          file_path: file_path,
          expected_count: extracted_count,
          extracted_count: extracted_count,
          checksum: checksum,
          status: :written,
          metadata: {
            endpoint: endpoint,
            base_columns: Constants.base_columns,
            tombstone_count: tombstone_count,
            incremental_overlap_window_hours: Hubspot::Export::Runner::OVERLAP_WINDOW.in_hours,
            requested_properties: requested_properties,
            observed_properties: observed_properties,
            schema_drift: {
              unexpected_properties: unexpected_properties,
              missing_requested_properties: missing_requested_properties,
              unexpected_count: unexpected_properties.size,
              missing_count: missing_requested_properties.size
            },
            deletion_strategy: {
              flags: ["record.archived", "record.isDeleted"],
              recycle_bin_adapter: {
                status: "fallback_only",
                checked_action_candidates: [
                  "HUBSPOT_HUBSPOT_LIST_RECYCLED_RECORDS",
                  "HUBSPOT_LIST_RECYCLED_RECORDS"
                ],
                reason: "Composio recycle-bin adapter not yet wired; relying on archived/isDeleted markers"
              }
            }
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
