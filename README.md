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

## Authentication (Resend Magic Link)

This app now requires authentication via magic link email and only allows `@fintoc.com` addresses.

Required env vars:

- `RESEND_API_KEY`
- `RESEND_FROM_EMAIL` (optional, default: `Clon Hubspot <auth@fintoc.com>`)

Flow:

1. User goes to `/login`.
2. Enters `@fintoc.com` email.
3. App sends magic link through Resend.
4. User clicks `/magic/:token` and gets authenticated.
