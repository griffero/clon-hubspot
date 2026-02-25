module Api
  module V1
    class ContactsController < BaseController
      def index
        contacts = Contact.ordered
        contacts = contacts.search(params[:q]) if params[:q].present?
        pagy, records = pagy(contacts, limit: params.fetch(:per_page, 25).to_i)
        render json: {
          contacts: records.map { |c| contact_json(c) },
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        contact = Contact.find(params[:id])
        render json: {
          contact: contact_json(contact).merge(
            deals: contact.associated_deals.includes(:stage, :pipeline).map { |d| deal_summary(d) }
          )
        }
      end

      private

      def contact_json(contact)
        {
          id: contact.id,
          hubspot_id: contact.hubspot_id,
          first_name: contact.first_name,
          last_name: contact.last_name,
          full_name: contact.full_name,
          email: contact.email,
          phone: contact.phone,
          company_name: contact.company_name,
          job_title: contact.job_title,
          lifecycle_stage: contact.lifecycle_stage
        }
      end

      def deal_summary(deal)
        { id: deal.id, name: deal.name, amount: deal.amount, stage_name: deal.stage&.label }
      end
    end
  end
end
