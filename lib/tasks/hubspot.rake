namespace :hubspot do
  desc "Sync all data from HubSpot API into local database"
  task sync: :environment do
    Hubspot::Sync::FullSync.call
  end
end
