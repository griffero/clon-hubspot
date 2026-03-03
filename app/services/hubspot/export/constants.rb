module Hubspot
  module Export
    module Constants
      module_function

      def object_extractors
        [
          {
            extractor_key: "crm_contacts",
            object_type: "contacts",
            list_action: "HUBSPOT_HUBSPOT_LIST_CONTACTS",
            search_action: "HUBSPOT_SEARCH_CONTACTS_BY_CRITERIA",
            properties: Hubspot::Properties::CONTACTS
          },
          {
            extractor_key: "crm_companies",
            object_type: "companies",
            list_action: "HUBSPOT_HUBSPOT_LIST_COMPANIES",
            search_action: "HUBSPOT_HUBSPOT_SEARCH_COMPANIES",
            properties: Hubspot::Properties::COMPANIES
          },
          {
            extractor_key: "crm_deals",
            object_type: "deals",
            list_action: "HUBSPOT_HUBSPOT_LIST_DEALS",
            search_action: "HUBSPOT_HUBSPOT_SEARCH_DEALS",
            properties: Hubspot::Properties::DEALS
          }
        ]
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
            action_candidates: ["HUBSPOT_RETRIEVE_ALL_PIPELINES"],
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
