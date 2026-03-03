# clon-hubspot

Rails app with HubSpot sync APIs and a production-style export foundation.

## HubSpot Export Foundation

See:

- `docs/hubspot_export_foundation.md`
- `docs/hubspot_export_runbook.md`

Core commands:

- `bin/rails "export:full_dump[portal_id]"`
- `bin/rails "export:incremental[portal_id]"`
- `bin/rails "export:resume[run_id]"`
- `bin/rails "export:verify[run_id]"`
- `bin/rails "export:reconcile[run_id]"`
- `bin/rails "export:coverage[run_id]"`
