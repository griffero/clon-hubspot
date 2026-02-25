class Contact < ApplicationRecord
  scope :search, ->(query) {
    where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR company_name ILIKE :q",
          q: "%#{query}%")
  }
  scope :ordered, -> { order(:last_name, :first_name) }

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def associated_deals
    hubspot_ids = HubspotAssociation.where(
      from_object_type: "deal", to_object_type: "contact", to_hubspot_id: hubspot_id
    ).pluck(:from_hubspot_id)
    Deal.where(hubspot_id: hubspot_ids)
  end
end
