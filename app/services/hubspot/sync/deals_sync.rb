module Hubspot
  module Sync
    class DealsSync
      def self.call(filters: [])
        raw_deals = ObjectsFetcher.call(
          "deals",
          properties: Properties::DEALS,
          associations: %w[contacts companies],
          filters: filters
        )

        raw_deals.each do |rd|
          props = rd["properties"] || {}
          stage_hubspot_id = props["dealstage"]
          pipeline_hubspot_id = props["pipeline"]

          stage = Stage.find_by(hubspot_id: stage_hubspot_id)
          pipeline = Pipeline.find_by(hubspot_id: pipeline_hubspot_id)
          next unless stage && pipeline

          Deal.find_or_initialize_by(hubspot_id: rd["id"]).update!(
            name: props["dealname"],
            amount: props["amount"]&.to_d,
            close_date: props["closedate"]&.to_date,
            stage: stage,
            pipeline: pipeline,
            hubspot_owner_id: props["hubspot_owner_id"]
          )

          sync_associations(rd)
        end

        Rails.logger.info "[HubSpot Sync] Synced #{raw_deals.size} deals"
      end

      def self.sync_associations(raw_deal)
        deal_id = raw_deal["id"]
        associations = raw_deal["associations"] || {}

        associations.each do |object_type, assoc_data|
          results = assoc_data["results"] || []
          results.each do |result|
            HubspotAssociation.find_or_create_by!(
              from_object_type: "deal",
              from_hubspot_id: deal_id,
              to_object_type: object_type.singularize,
              to_hubspot_id: result["id"]
            )
          end
        end
      end
    end
  end
end
