class Deal < ApplicationRecord
  belongs_to :stage
  belongs_to :pipeline

  scope :ordered, -> { order(amount: :desc) }

  def associated_contacts
    hubspot_ids = HubspotAssociation.where(
      from_object_type: "deal", from_hubspot_id: hubspot_id, to_object_type: "contact"
    ).pluck(:to_hubspot_id)
    Contact.where(hubspot_id: hubspot_ids)
  end

  def associated_companies
    hubspot_ids = HubspotAssociation.where(
      from_object_type: "deal", from_hubspot_id: hubspot_id, to_object_type: "company"
    ).pluck(:to_hubspot_id)
    Company.where(hubspot_id: hubspot_ids)
  end
end
