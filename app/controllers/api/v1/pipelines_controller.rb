module Api
  module V1
    class PipelinesController < BaseController
      def index
        pipelines = Pipeline.active.ordered.includes(:stages, :deals)
        render json: {
          pipelines: pipelines.map { |p| pipeline_json(p) }
        }
      end

      def show
        pipeline = Pipeline.includes(:stages, :deals).find(params[:id])
        render json: {
          pipeline: pipeline_json(pipeline).merge(
            stages: pipeline.stages.ordered.map do |s|
              {
                id: s.id,
                hubspot_id: s.hubspot_id,
                label: s.label,
                display_order: s.display_order,
                probability: s.probability,
                is_closed: s.is_closed,
                deal_count: s.deals.size,
                total_value: s.total_deal_value
              }
            end
          )
        }
      end

      private

      def pipeline_json(pipeline)
        {
          id: pipeline.id,
          hubspot_id: pipeline.hubspot_id,
          label: pipeline.label,
          display_order: pipeline.display_order,
          stage_count: pipeline.stages.size,
          deal_count: pipeline.deals.size,
          total_value: pipeline.total_deal_value
        }
      end
    end
  end
end
