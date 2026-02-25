module Api
  module V1
    class DealsController < BaseController
      def index
        if params[:view] == "kanban"
          render_kanban
        else
          deals = Deal.includes(:stage, :pipeline).ordered
          deals = deals.where(pipeline_id: params[:pipeline_id]) if params[:pipeline_id].present?
          pagy, records = pagy(deals, limit: params.fetch(:per_page, 25).to_i)
          render json: {
            deals: records.map { |d| deal_json(d) },
            pagination: pagy_metadata(pagy)
          }
        end
      end

      def show
        deal = Deal.includes(:stage, :pipeline).find(params[:id])
        render json: {
          deal: deal_json(deal).merge(
            contacts: deal.associated_contacts.map { |c| contact_summary(c) },
            companies: deal.associated_companies.map { |co| company_summary(co) }
          )
        }
      end

      private

      def render_kanban
        pipeline_id = params[:pipeline_id]
        pipeline = pipeline_id.present? ? Pipeline.find(pipeline_id) : Pipeline.active.ordered.first
        return render(json: { pipeline: nil, stages: [] }) unless pipeline

        stages = pipeline.stages.ordered.includes(:deals)
        render json: {
          pipeline: { id: pipeline.id, label: pipeline.label },
          stages: stages.map do |stage|
            {
              id: stage.id,
              hubspot_id: stage.hubspot_id,
              label: stage.label,
              display_order: stage.display_order,
              probability: stage.probability,
              is_closed: stage.is_closed,
              total_value: stage.total_deal_value,
              deals: stage.deals.ordered.map { |d| deal_json(d) }
            }
          end
        }
      end

      def deal_json(deal)
        {
          id: deal.id,
          hubspot_id: deal.hubspot_id,
          name: deal.name,
          amount: deal.amount,
          close_date: deal.close_date,
          stage_name: deal.stage&.label,
          stage_id: deal.stage_id,
          pipeline_name: deal.pipeline&.label,
          pipeline_id: deal.pipeline_id
        }
      end

      def contact_summary(contact)
        { id: contact.id, name: contact.full_name, email: contact.email }
      end

      def company_summary(company)
        { id: company.id, name: company.name, domain: company.domain }
      end
    end
  end
end
