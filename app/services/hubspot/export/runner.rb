module Hubspot
  module Export
    class Runner
      OVERLAP_WINDOW = 24.hours

      def self.full_dump(portal_id:)
        run = create_run!(portal_id: portal_id, mode: :full)
        execute!(run: run)
      end

      def self.incremental(portal_id:)
        run = create_run!(portal_id: portal_id, mode: :incremental)
        execute!(run: run)
      end

      def self.resume(run_id:)
        run = ExportRun.find_by!(run_id: run_id)
        execute!(run: run)
      end

      def self.execute!(run:)
        return run if run.succeeded?

        run.start! unless run.running?

        store = FileStore.new(run)
        store.ensure_layout!
        client = Hubspot::Client.default

        MetadataExtractor.new(run: run, portal_id: run.portal_id, store: store, client: client).call

        dynamic_objects = discover_custom_objects(store)
        extractors = Constants.object_extractors(dynamic_objects: dynamic_objects)
        incremental_since_map = incremental_since_for(run, extractors)

        extractors.each do |extractor_config|
          ObjectExtractor.new(
            run: run,
            portal_id: run.portal_id,
            store: store,
            client: client,
            config: extractor_config,
            incremental_since: incremental_since_map[extractor_config.fetch(:extractor_key)]
          ).call
        end

        Constants::ASSOCIATION_SOURCE_OBJECTS.each do |source_object|
          AssociationsExtractor.new(
            run: run,
            portal_id: run.portal_id,
            store: store,
            client: client,
            source_object: source_object,
            target_objects: Constants::ASSOCIATION_TARGET_OBJECTS
          ).call
        end

        run.update!(
          total_records: run.export_tables.sum(:extracted_count),
          stats: run.stats.merge(
            "incremental_since" => incremental_since_map.transform_values { |v| v&.iso8601 },
            "custom_object_count" => dynamic_objects.size
          )
        )

        ManifestWriter.new(run: run, store: store).write!
        run.finish!(final_status: :succeeded)
        run
      rescue Hubspot::RetryExhaustedError => e
        run.finish!(final_status: :retry_exhausted, error_message: e.message)
        raise
      rescue StandardError => e
        run.finish!(final_status: :failed, error_message: e.message)
        raise
      end

      def self.create_run!(portal_id:, mode:)
        resolved_portal_id = portal_id.presence || Hubspot::Configuration.default_portal_id
        raise Hubspot::ConfigurationError, "Missing portal_id. Pass portal_id or set HUBSPOT_PORTAL_ID." if resolved_portal_id.blank?

        timestamp = Time.current.utc.strftime("%Y-%m-%dT%H-%M-%SZ")
        ExportRun.create!(
          run_id: timestamp,
          portal_id: resolved_portal_id,
          mode: mode,
          status: :queued,
          stats: {}
        )
      end

      def self.incremental_since_for(run, extractors)
        return {} unless run.incremental?

        previous = ExportRun.where(portal_id: run.portal_id, mode: :incremental, status: :succeeded)
                            .where.not(id: run.id)
                            .order(finished_at: :desc)
                            .first

        extractors.each_with_object({}) do |config, memo|
          key = config.fetch(:extractor_key)
          checkpoint = previous&.export_checkpoints&.find_by(extractor_key: key)
          watermark = checkpoint&.high_watermark
          fallback = previous&.finished_at
          memo[key] = [ watermark, fallback ].compact.max&.-(OVERLAP_WINDOW)
        end
      end

      def self.discover_custom_objects(store)
        schemas_path = store.absolute_path("metadata/schemas/schemas.json")
        return [] unless File.exist?(schemas_path)

        payload = JSON.parse(File.read(schemas_path))
        schemas = payload.dig("data", "results") || payload.dig("data", "objects") || payload.dig("data") || []

        Array(schemas).select do |schema|
          name = schema["name"].to_s
          schema["objectTypeId"].present? && !Constants::ASSOCIATION_SOURCE_OBJECTS.include?(name)
        end
      rescue JSON::ParserError
        []
      end

      private_class_method :create_run!, :incremental_since_for, :discover_custom_objects
    end
  end
end
