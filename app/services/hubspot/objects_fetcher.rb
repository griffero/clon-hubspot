module Hubspot
  class ObjectsFetcher
    BATCH_SIZE = 100

    ACTION_MAP = {
      "deals" => "HUBSPOT_HUBSPOT_LIST_DEALS",
      "contacts" => "HUBSPOT_HUBSPOT_LIST_CONTACTS",
      "companies" => "HUBSPOT_HUBSPOT_LIST_COMPANIES"
    }.freeze

    SEARCH_ACTION_MAP = {
      "deals" => "HUBSPOT_HUBSPOT_SEARCH_DEALS",
      "contacts" => "HUBSPOT_SEARCH_CONTACTS_BY_CRITERIA",
      "companies" => "HUBSPOT_HUBSPOT_SEARCH_COMPANIES"
    }.freeze

    def self.call(object_type, properties:, associations: [], filters: [])
      all_results = []
      after = nil

      if filters.any?
        fetch_with_search(object_type, properties, filters, all_results)
      else
        fetch_with_list(object_type, properties, all_results)
      end

      all_results
    end

    def self.fetch_with_list(object_type, properties, all_results)
      action = ACTION_MAP[object_type]
      after = nil

      loop do
        input = { limit: BATCH_SIZE, properties: properties }
        input[:after] = after if after

        data = Client.execute_action(action, input)
        results = data["results"] || []
        all_results.concat(results)

        after = data.dig("paging", "next", "after")
        break if after.nil? || results.empty?
      end
    end

    def self.fetch_with_search(object_type, properties, filters, all_results)
      action = SEARCH_ACTION_MAP[object_type]
      after = nil

      loop do
        input = {
          limit: BATCH_SIZE,
          properties: properties,
          filterGroups: [{ filters: filters }]
        }
        input[:after] = after if after

        data = Client.execute_action(action, input)
        results = data["results"] || []
        all_results.concat(results)

        after = data.dig("paging", "next", "after")
        break if after.nil? || results.empty?
      end
    end
  end
end
