require "json"
require "digest"

module Hubspot
  module Export
    class AssociationsExtractor
      BATCH_SIZE = 100

      def initialize(run:, portal_id:, store:, client:, source_object:, target_objects:)
        @run = run
        @portal_id = portal_id
        @store = store
        @client = client
        @source_object = source_object
        @target_objects = target_objects
      end

      def call
        checkpoint = CheckpointStore.fetch_or_create!(run: run, portal_id: portal_id, extractor_key: extractor_key)
        return checkpoint if checkpoint.succeeded?

        checkpoint.mark_running!
        source_ids = load_source_ids

        if source_ids.empty?
          upsert_table!(count: 0, endpoint: nil, by_target: {}, warning: "No source records available")
          checkpoint.update!(records_exported: 0, metadata: checkpoint.metadata.merge("warning" => "no source ids"))
          checkpoint.mark_succeeded!
          return checkpoint
        end

        start_offset = checkpoint.metadata.fetch("offset", 0).to_i
        total_count = checkpoint.records_exported
        by_target = checkpoint.metadata.fetch("by_target", {})
        resolved_action = checkpoint.metadata["resolved_action"]
        file_path = "raw_jsonl/object=#{source_object}_associations/part-00001.jsonl"

        source_ids.each_slice(BATCH_SIZE).with_index do |slice, batch_idx|
          next if batch_idx < start_offset

          rows, resolved_action, by_target = fetch_association_rows(slice, resolved_action, by_target)
          store.append_jsonl(file_path, rows)
          total_count += rows.size

          checkpoint.update!(
            records_exported: total_count,
            cursor: batch_idx.to_s,
            metadata: checkpoint.metadata.merge(
              "offset" => batch_idx + 1,
              "source_id_count" => source_ids.size,
              "by_target" => by_target,
              "resolved_action" => resolved_action
            )
          )
          run.heartbeat!
        end

        upsert_table!(count: total_count, endpoint: resolved_action, by_target: by_target)
        checkpoint.mark_succeeded!
        checkpoint
      rescue Hubspot::RetryExhaustedError => e
        checkpoint.mark_retry_exhausted!(e.message)
        raise
      rescue StandardError => e
        checkpoint.mark_failed!(e.message)
        raise
      end

      private

      attr_reader :run, :portal_id, :store, :client, :source_object, :target_objects

      def extractor_key
        "assoc_#{source_object}"
      end

      def load_source_ids
        path = store.absolute_path("raw_jsonl/object=#{source_object}/part-00001.jsonl")
        return [] unless File.exist?(path)

        ids = []
        File.foreach(path) do |line|
          parsed = JSON.parse(line)
          id = parsed["_record_id"] || parsed["id"]
          ids << id.to_s if id.present?
        rescue JSON::ParserError
          next
        end
        ids.uniq
      end

      def fetch_association_rows(source_ids, preferred_action, by_target)
        rows = []
        resolved_action = preferred_action

        target_objects.each do |to_object|
          response, resolved_action = fetch_association_page(
            source_ids: source_ids,
            target_object: to_object,
            preferred_action: resolved_action
          )

          links = extract_links(response)
          by_target[to_object] = by_target.fetch(to_object, 0) + links.size

          links.each do |link|
            rows << normalize_link(link, to_object, resolved_action)
          end
        rescue StandardError
          by_target[to_object] = by_target.fetch(to_object, 0)
          next
        end

        [ rows, resolved_action, by_target ]
      end

      def fetch_association_page(source_ids:, target_object:, preferred_action: nil)
        candidates = [ preferred_action, "HUBSPOT_HUBSPOT_BATCH_READ_ASSOCIATIONS", "HUBSPOT_BATCH_READ_ASSOCIATIONS" ].compact.uniq
        last_error = nil

        payload_candidates = [
          {
            fromObjectType: source_object,
            toObjectType: target_object,
            inputs: source_ids.map { |id| { id: id } }
          },
          {
            fromObjectType: source_object,
            toObjectType: target_object,
            objectIds: source_ids
          }
        ]

        candidates.each do |action|
          payload_candidates.each do |payload|
            return [ client.execute_action(action, payload), action ]
          rescue StandardError => e
            last_error = e
          end
        end

        raise(last_error || "No association action candidates succeeded")
      end

      def extract_links(response)
        (response["results"] || []).flat_map do |row|
          from_id = row["from"]&.[]("id") || row["fromObjectId"] || row["id"]
          tos = row["to"] || row["toObjectIds"] || row["associations"] || []
          tos = tos.values.flatten if tos.is_a?(Hash)

          Array(tos).filter_map do |to_row|
            to_id = to_row["id"] || to_row["toObjectId"] || to_row
            next if from_id.blank? || to_id.blank?

            {
              "from_id" => from_id.to_s,
              "to_id" => to_id.to_s,
              "association_type_id" => to_row.is_a?(Hash) ? to_row["typeId"] : nil,
              "association_category" => to_row.is_a?(Hash) ? to_row["category"] : nil,
              "association_label" => to_row.is_a?(Hash) ? to_row["label"] : nil,
              "raw" => {
                "from" => row["from"],
                "to" => to_row
              }
            }
          end
        end
      end

      def normalize_link(link, to_object, endpoint)
        raw_hash = Digest::SHA256.hexdigest(JSON.generate(link["raw"]))

        {
          "_hs_portal_id" => portal_id,
          "_object_type" => "#{source_object}_associations",
          "_record_id" => "#{source_object}:#{link["from_id"]}:#{to_object}:#{link["to_id"]}",
          "_extracted_at" => Time.current.iso8601,
          "_cursor" => nil,
          "_source_endpoint" => endpoint,
          "_run_id" => run.run_id,
          "_raw_hash" => raw_hash,
          "_deleted" => false,
          "_valid_from" => nil,
          "_valid_to" => nil,
          "from_object_type" => source_object,
          "from_object_id" => link["from_id"],
          "to_object_type" => to_object,
          "to_object_id" => link["to_id"],
          "association_type_id" => link["association_type_id"],
          "association_category" => link["association_category"],
          "association_label" => link["association_label"]
        }
      end

      def upsert_table!(count:, endpoint:, by_target:, warning: nil)
        run.export_tables.find_or_initialize_by(extractor_key: extractor_key).update!(
          object_type: "#{source_object}_associations",
          file_path: "raw_jsonl/object=#{source_object}_associations/part-00001.jsonl",
          expected_count: count,
          extracted_count: count,
          checksum: store.checksum("raw_jsonl/object=#{source_object}_associations/part-00001.jsonl"),
          status: :written,
          metadata: {
            endpoint: endpoint,
            source_object: source_object,
            target_objects: target_objects,
            associated_rows_by_target: by_target,
            warning: warning,
            todo: "Add association labels/types metadata snapshot export"
          }
        )
      end
    end
  end
end
