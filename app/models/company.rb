class Company < ApplicationRecord
  scope :search, ->(query) {
    where("name ILIKE :q OR domain ILIKE :q OR industry ILIKE :q", q: "%#{query}%")
  }
  scope :ordered, -> { order(:name) }

  def associated_deals
    hubspot_ids = HubspotAssociation.where(
      from_object_type: "deal", to_object_type: "company", to_hubspot_id: hubspot_id
    ).pluck(:from_hubspot_id)
    Deal.where(hubspot_id: hubspot_ids)
  end

  def associated_contacts
    hubspot_ids = HubspotAssociation.where(
      from_object_type: "contact", to_object_type: "company", to_hubspot_id: hubspot_id
    ).pluck(:from_hubspot_id)
    Contact.where(hubspot_id: hubspot_ids)
  end
end
