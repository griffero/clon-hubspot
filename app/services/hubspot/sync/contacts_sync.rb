module Hubspot
  module Sync
    class ContactsSync
      def self.call(filters: [])
        raw_contacts = ObjectsFetcher.call("contacts", properties: Properties::CONTACTS, filters: filters)

        raw_contacts.each do |rc|
          props = rc["properties"] || {}
          Contact.find_or_initialize_by(hubspot_id: rc["id"]).update!(
            email: props["email"],
            first_name: props["firstname"],
            last_name: props["lastname"],
            phone: props["phone"],
            company_name: props["company"],
            job_title: props["jobtitle"],
            lifecycle_stage: props["lifecyclestage"]
          )
        end

        Rails.logger.info "[HubSpot Sync] Synced #{raw_contacts.size} contacts"
      end
    end
  end
end
