module Hubspot
  module Configuration
    module_function

    def composio_api_key
      ENV["COMPOSIO_API_KEY"].presence || Rails.application.credentials.dig(:composio, :api_key)
    end

    def composio_connected_account_id
      ENV["COMPOSIO_CONNECTED_ACCOUNT_ID"].presence || Rails.application.credentials.dig(:composio, :connected_account_id)
    end

    def default_portal_id
      ENV["HUBSPOT_PORTAL_ID"].presence || Rails.application.credentials.dig(:hubspot, :portal_id)
    end
  end
end
