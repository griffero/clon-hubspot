module Hubspot
  module Sync
    class FullSync
      def self.call
        Rails.logger.info "[HubSpot Sync] Starting full sync..."
        start_time = Time.current

        PipelinesSync.call
        ContactsSync.call
        CompaniesSync.call
        DealsSync.call

        elapsed = (Time.current - start_time).round(1)
        Rails.logger.info "[HubSpot Sync] Full sync completed in #{elapsed}s"
      end
    end
  end
end
