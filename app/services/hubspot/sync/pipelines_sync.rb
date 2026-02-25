module Hubspot
  module Sync
    class PipelinesSync
      def self.call
        raw_pipelines = PipelinesFetcher.call

        raw_pipelines.each do |rp|
          pipeline_id = rp["pipelineId"] || rp["id"]
          pipeline = Pipeline.find_or_initialize_by(hubspot_id: pipeline_id)
          pipeline.update!(
            label: rp["label"],
            display_order: rp["displayOrder"] || rp["display_order"],
            active: rp["archived"] != true
          )

          (rp["stages"] || []).each do |rs|
            stage_id = rs["stageId"] || rs["id"]
            stage = Stage.find_or_initialize_by(hubspot_id: stage_id)
            stage.update!(
              pipeline: pipeline,
              label: rs["label"],
              display_order: rs["displayOrder"] || rs["display_order"],
              probability: rs.dig("metadata", "probability"),
              is_closed: rs.dig("metadata", "isClosed") == "true"
            )
          end
        end

        Rails.logger.info "[HubSpot Sync] Synced #{raw_pipelines.size} pipelines"
      end
    end
  end
end
