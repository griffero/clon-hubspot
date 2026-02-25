class HubspotAssociation < ApplicationRecord
  validates :from_object_type, :from_hubspot_id, :to_object_type, :to_hubspot_id, presence: true
end
