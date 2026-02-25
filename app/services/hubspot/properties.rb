module Hubspot
  module Properties
    DEALS = %w[
      dealname amount closedate dealstage pipeline hubspot_owner_id
    ].freeze

    CONTACTS = %w[
      email firstname lastname phone company jobtitle lifecyclestage
    ].freeze

    COMPANIES = %w[
      name domain industry phone city country numberofemployees annualrevenue
    ].freeze
  end
end
