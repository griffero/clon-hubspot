module Hubspot
  module Export
    module Constants
      module_function

      STANDARD_OBJECTS = [
        { object_type: "contacts", extractor_key: "crm_contacts", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_CONTACTS" ], search_action_candidates: [ "HUBSPOT_SEARCH_CONTACTS_BY_CRITERIA" ] },
        { object_type: "companies", extractor_key: "crm_companies", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_COMPANIES" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_COMPANIES" ] },
        { object_type: "deals", extractor_key: "crm_deals", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_DEALS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_DEALS" ] },
        { object_type: "tickets", extractor_key: "crm_tickets", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_TICKETS", "HUBSPOT_LIST_TICKETS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_TICKETS", "HUBSPOT_SEARCH_TICKETS" ] },
        { object_type: "leads", extractor_key: "crm_leads", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_LEADS", "HUBSPOT_LIST_LEADS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_LEADS", "HUBSPOT_SEARCH_LEADS" ] },
        { object_type: "products", extractor_key: "crm_products", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_PRODUCTS", "HUBSPOT_LIST_PRODUCTS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_PRODUCTS", "HUBSPOT_SEARCH_PRODUCTS" ] },
        { object_type: "line_items", extractor_key: "crm_line_items", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_LINE_ITEMS", "HUBSPOT_LIST_LINE_ITEMS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_LINE_ITEMS", "HUBSPOT_SEARCH_LINE_ITEMS" ] },
        { object_type: "quotes", extractor_key: "crm_quotes", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_QUOTES", "HUBSPOT_LIST_QUOTES" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_QUOTES", "HUBSPOT_SEARCH_QUOTES" ] },
        { object_type: "calls", extractor_key: "crm_calls", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_CALLS", "HUBSPOT_LIST_CALLS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_CALLS", "HUBSPOT_SEARCH_CALLS" ] },
        { object_type: "emails", extractor_key: "crm_emails", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_EMAILS", "HUBSPOT_LIST_EMAILS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_EMAILS", "HUBSPOT_SEARCH_EMAILS" ] },
        { object_type: "meetings", extractor_key: "crm_meetings", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_MEETINGS", "HUBSPOT_LIST_MEETINGS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_MEETINGS", "HUBSPOT_SEARCH_MEETINGS" ] },
        { object_type: "notes", extractor_key: "crm_notes", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_NOTES", "HUBSPOT_LIST_NOTES" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_NOTES", "HUBSPOT_SEARCH_NOTES" ] },
        { object_type: "tasks", extractor_key: "crm_tasks", list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_TASKS", "HUBSPOT_LIST_TASKS" ], search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_TASKS", "HUBSPOT_SEARCH_TASKS" ] }
      ].freeze

      ASSOCIATION_SOURCE_OBJECTS = %w[
        contacts companies deals tickets leads products line_items quotes calls emails meetings notes tasks
      ].freeze

      ASSOCIATION_TARGET_OBJECTS = %w[
        contacts companies deals tickets line_items quotes calls emails meetings notes tasks
      ].freeze

      def object_extractors(dynamic_objects: [])
        standard = STANDARD_OBJECTS.map do |cfg|
          {
            extractor_key: cfg.fetch(:extractor_key),
            object_type: cfg.fetch(:object_type),
            list_action_candidates: cfg.fetch(:list_action_candidates),
            search_action_candidates: cfg.fetch(:search_action_candidates),
            properties: Hubspot::Properties.for_object(cfg.fetch(:object_type))
          }
        end

        dynamic = dynamic_objects.map do |schema|
          name = schema["name"].presence || schema["fullyQualifiedName"].presence || schema["objectTypeId"].presence || "custom_object"
          object_type = "custom_#{name.parameterize(separator: "_")}"
          {
            extractor_key: "crm_#{object_type}",
            object_type: object_type,
            list_action_candidates: [ "HUBSPOT_HUBSPOT_LIST_OBJECTS", "HUBSPOT_LIST_OBJECTS" ],
            search_action_candidates: [ "HUBSPOT_HUBSPOT_SEARCH_OBJECTS", "HUBSPOT_SEARCH_OBJECTS" ],
            properties: custom_object_properties(schema),
            custom_object_schema: schema,
            custom_object_name: name,
            custom_object_id: schema["objectTypeId"]
          }
        end

        standard + dynamic
      end

      def custom_object_properties(schema)
        schema_properties = Array(schema["properties"]).filter_map do |entry|
          next unless entry.is_a?(Hash)

          entry["name"] || entry["propertyName"]
        end

        (schema_properties + ["hs_lastmodifieddate"]).compact.uniq
      end

      def metadata_endpoints
        [
          {
            extractor_key: "metadata_properties_contacts",
            object_type: "properties_contacts",
            output_path: "metadata/properties/contacts.json",
            action_candidates: [
              "HUBSPOT_HUBSPOT_LIST_PROPERTIES",
              "HUBSPOT_LIST_PROPERTIES"
            ],
            input: { objectType: "contacts" }
          },
          {
            extractor_key: "metadata_properties_companies",
            object_type: "properties_companies",
            output_path: "metadata/properties/companies.json",
            action_candidates: [
              "HUBSPOT_HUBSPOT_LIST_PROPERTIES",
              "HUBSPOT_LIST_PROPERTIES"
            ],
            input: { objectType: "companies" }
          },
          {
            extractor_key: "metadata_properties_deals",
            object_type: "properties_deals",
            output_path: "metadata/properties/deals.json",
            action_candidates: [
              "HUBSPOT_HUBSPOT_LIST_PROPERTIES",
              "HUBSPOT_LIST_PROPERTIES"
            ],
            input: { objectType: "deals" }
          },
          {
            extractor_key: "metadata_pipelines_deals",
            object_type: "pipelines_deals",
            output_path: "metadata/pipelines/deals.json",
            action_candidates: [ "HUBSPOT_RETRIEVE_ALL_PIPELINES" ],
            input: { objectType: "deals" }
          },
          {
            extractor_key: "metadata_owners",
            object_type: "owners",
            output_path: "metadata/owners/owners.json",
            action_candidates: [
              "HUBSPOT_HUBSPOT_LIST_OWNERS",
              "HUBSPOT_LIST_OWNERS"
            ],
            input: {}
          },
          {
            extractor_key: "metadata_schemas",
            object_type: "schemas",
            output_path: "metadata/schemas/schemas.json",
            action_candidates: [
              "HUBSPOT_HUBSPOT_LIST_SCHEMAS",
              "HUBSPOT_LIST_SCHEMAS"
            ],
            input: {}
          }
        ]
      end

      def base_columns
        %w[
          _hs_portal_id
          _object_type
          _record_id
          _extracted_at
          _cursor
          _source_endpoint
          _run_id
          _raw_hash
          _deleted
          _valid_from
          _valid_to
        ]
      end
    end
  end
end
