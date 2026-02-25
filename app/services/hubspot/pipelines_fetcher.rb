module Hubspot
  class PipelinesFetcher
    def self.call
      data = Client.execute_action("HUBSPOT_RETRIEVE_ALL_PIPELINES", { objectType: "deals" })
      data["results"] || []
    end
  end
end
