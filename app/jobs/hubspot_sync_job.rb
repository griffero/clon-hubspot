class HubspotSyncJob < ApplicationJob
  queue_as :default

  def perform
    Hubspot::Sync::FullSync.call
  end
end
