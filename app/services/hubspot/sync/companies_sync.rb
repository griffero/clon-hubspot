module Hubspot
  module Sync
    class CompaniesSync
      def self.call(filters: [])
        raw_companies = ObjectsFetcher.call("companies", properties: Properties::COMPANIES, filters: filters)

        raw_companies.each do |rc|
          props = rc["properties"] || {}
          Company.find_or_initialize_by(hubspot_id: rc["id"]).update!(
            name: props["name"],
            domain: props["domain"],
            industry: props["industry"],
            phone: props["phone"],
            city: props["city"],
            country: props["country"],
            number_of_employees: props["numberofemployees"]&.to_i,
            annual_revenue: props["annualrevenue"]&.to_d
          )
        end

        Rails.logger.info "[HubSpot Sync] Synced #{raw_companies.size} companies"
      end
    end
  end
end
