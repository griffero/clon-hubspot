module Api
  module V1
    class CompaniesController < BaseController
      def index
        companies = Company.ordered
        companies = companies.search(params[:q]) if params[:q].present?
        pagy, records = pagy(companies, limit: params.fetch(:per_page, 25).to_i)
        render json: {
          companies: records.map { |c| company_json(c) },
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        company = Company.find(params[:id])
        render json: {
          company: company_json(company).merge(
            deals: company.associated_deals.includes(:stage, :pipeline).map { |d| deal_summary(d) },
            contacts: company.associated_contacts.map { |c| contact_summary(c) }
          )
        }
      end

      private

      def company_json(company)
        {
          id: company.id,
          hubspot_id: company.hubspot_id,
          name: company.name,
          domain: company.domain,
          industry: company.industry,
          phone: company.phone,
          city: company.city,
          country: company.country,
          number_of_employees: company.number_of_employees,
          annual_revenue: company.annual_revenue
        }
      end

      def deal_summary(deal)
        { id: deal.id, name: deal.name, amount: deal.amount, stage_name: deal.stage&.label }
      end

      def contact_summary(contact)
        { id: contact.id, name: contact.full_name, email: contact.email }
      end
    end
  end
end
