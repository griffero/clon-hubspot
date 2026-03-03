module Hubspot
  module Export
    class MetadataExtractor
      def initialize(run:, portal_id:, store:, client:)
        @run = run
        @portal_id = portal_id
        @store = store
        @client = client
      end

      def call
        checkpoint = CheckpointStore.fetch_or_create!(run: run, portal_id: portal_id, extractor_key: "metadata_discovery")
        return checkpoint if checkpoint.succeeded?

        checkpoint.mark_running!
        successful = 0
        failures = []

        Constants.metadata_endpoints.each do |definition|
          payload = fetch_payload(definition)
          next if payload.nil?

          store.write_json(definition.fetch(:output_path), payload)
          upsert_table!(definition, payload)
          successful += 1
        rescue StandardError => e
          failures << { extractor: definition.fetch(:extractor_key), error: e.message }
        end

        if successful.positive?
          checkpoint.update!(
            records_exported: successful,
            metadata: { failures: failures },
            cursor: nil
          )
          checkpoint.mark_succeeded!
        else
          message = "Metadata discovery failed: #{failures.map { |f| "#{f[:extractor]}=#{f[:error]}" }.join(", ")}"
          checkpoint.mark_failed!(message)
          raise message
        end

        checkpoint
      rescue Hubspot::RetryExhaustedError => e
        checkpoint.mark_retry_exhausted!(e.message)
        raise
      end

      private

      attr_reader :run, :portal_id, :store, :client

      def fetch_payload(definition)
        last_error = nil

        definition.fetch(:action_candidates).each do |action_name|
          response = client.execute_action(action_name, definition.fetch(:input))
          return {
            action: action_name,
            extracted_at: Time.current.iso8601,
            portal_id: portal_id,
            data: response
          }
        rescue StandardError => e
          last_error = e
        end

        raise(last_error || "No metadata action candidates succeeded")
      end

      def upsert_table!(definition, payload)
        run.export_tables.find_or_initialize_by(extractor_key: definition.fetch(:extractor_key)).update!(
          object_type: definition.fetch(:object_type),
          file_path: definition.fetch(:output_path),
          expected_count: nil,
          extracted_count: payload.dig(:data, "results")&.size || 1,
          checksum: store.checksum(definition.fetch(:output_path)),
          status: :written,
          metadata: {
            endpoint: payload[:action],
            extracted_at: payload[:extracted_at]
          }
        )
      end
    end
  end
end
