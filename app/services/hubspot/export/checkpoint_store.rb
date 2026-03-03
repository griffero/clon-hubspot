module Hubspot
  module Export
    class CheckpointStore
      def self.fetch_or_create!(run:, portal_id:, extractor_key:)
        ExportCheckpoint.find_or_create_by!(
          export_run: run,
          portal_id: portal_id,
          extractor_key: extractor_key
        )
      end
    end
  end
end
