module Hubspot
  module Properties
    DEALS = %w[
      dealname amount closedate dealstage pipeline hubspot_owner_id hs_lastmodifieddate
    ].freeze

    CONTACTS = %w[
      email firstname lastname phone company jobtitle lifecyclestage hs_lastmodifieddate
    ].freeze

    COMPANIES = %w[
      name domain industry phone city country numberofemployees annualrevenue hs_lastmodifieddate
    ].freeze

    TICKETS = %w[
      subject content hs_pipeline hs_pipeline_stage hs_ticket_priority hubspot_owner_id hs_lastmodifieddate
    ].freeze

    LEADS = %w[
      hs_lead_name hs_lead_status hs_lead_type hubspot_owner_id hs_lastmodifieddate
    ].freeze

    PRODUCTS = %w[
      name description price hs_sku hs_recurring_billing_period hs_lastmodifieddate
    ].freeze

    LINE_ITEMS = %w[
      name quantity price amount hs_product_id hs_lastmodifieddate
    ].freeze

    QUOTES = %w[
      hs_title hs_expiration_date hs_status hs_comments hs_lastmodifieddate
    ].freeze

    CALLS = %w[
      hs_call_title hs_call_body hs_call_duration hs_call_status hs_timestamp hs_lastmodifieddate
    ].freeze

    EMAILS = %w[
      hs_email_subject hs_email_text hs_email_direction hs_email_status hs_timestamp hs_lastmodifieddate
    ].freeze

    MEETINGS = %w[
      hs_meeting_title hs_meeting_body hs_meeting_start_time hs_meeting_end_time hs_timestamp hs_lastmodifieddate
    ].freeze

    NOTES = %w[
      hs_note_body hs_timestamp hs_lastmodifieddate
    ].freeze

    TASKS = %w[
      hs_task_subject hs_task_body hs_task_status hs_task_priority hs_task_type hs_timestamp hs_lastmodifieddate
    ].freeze

    OBJECT_PROPERTY_MAP = {
      "contacts" => CONTACTS,
      "companies" => COMPANIES,
      "deals" => DEALS,
      "tickets" => TICKETS,
      "leads" => LEADS,
      "products" => PRODUCTS,
      "line_items" => LINE_ITEMS,
      "quotes" => QUOTES,
      "calls" => CALLS,
      "emails" => EMAILS,
      "meetings" => MEETINGS,
      "notes" => NOTES,
      "tasks" => TASKS
    }.freeze

    module_function

    def for_object(object_type)
      OBJECT_PROPERTY_MAP.fetch(object_type.to_s, [ "hs_lastmodifieddate" ])
    end
  end
end
