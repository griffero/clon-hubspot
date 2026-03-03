# HubSpot Export Foundation

This project includes a resumable, DB-backed HubSpot export pipeline (Phase 0 + Phase 1+ extensions) using Composio actions.

## Credentials and Configuration

Do not hardcode secrets. Configure via environment variables or Rails credentials:

- `COMPOSIO_API_KEY`
- `COMPOSIO_CONNECTED_ACCOUNT_ID`
- `HUBSPOT_PORTAL_ID` (default portal, optional if passed to rake tasks)

Rails credentials fallback keys:

- `composio.api_key`
- `composio.connected_account_id`
- `hubspot.portal_id`

## Commands

- Full dump: `bin/rails "export:full_dump[portal_id]"`
- Incremental: `bin/rails "export:incremental[portal_id]"`
- Resume: `bin/rails "export:resume[run_id]"`
- Verify: `bin/rails "export:verify[run_id]"`
- Reconcile: `bin/rails "export:reconcile[run_id]"`
- Coverage matrix: `bin/rails "export:coverage[run_id]"`

If `portal_id` is omitted, `HUBSPOT_PORTAL_ID` (or credentials fallback) is used.

## What Gets Exported

Current object registry coverage:

- CRM objects: contacts, companies, deals, tickets, leads, products, line items, quotes, calls, emails, meetings, notes, tasks
- Dynamic custom objects discovered from schemas metadata
- Associations fanout export per source object (`*_associations` JSONL tables)
- Associations labels/type metadata snapshots: `metadata/associations/<source>.json`
- Metadata snapshots: properties, pipelines, owners, schemas

## Output Layout

All output is written under:

- `exports/run_id=<RUN_ID>/`

Key files:

- `manifests/run_manifest.json`
- `manifests/tables_manifest.json`
- `manifests/checksum_manifest.json`
- `manifests/reconciliation_report.json`
- `manifests/coverage_matrix.json`
- `manifests/coverage_matrix.md`
- `manifests/run_report.json`
- `manifests/run_report.md`
- `manifests/verification_report.json` (created by verify command)
- `raw_jsonl/object=<object>/part-00001.jsonl`
- `metadata/.../*.json`

## Reliability Behavior

- Export run state persisted in `export_runs`.
- Per-extractor resumable checkpoints in `export_checkpoints`.
- Per-table/file tracking in `export_tables`.
- Retry/backoff policy in `Hubspot::Client`:
  - retries `429`, `500`, `502`, `503`, `504`
  - jittered exponential backoff
  - honors `Retry-After` when present

## Resume Semantics

A resumed run (`export:resume`) continues from the saved per-extractor cursor in `export_checkpoints`.

- Completed extractors are skipped.
- In-progress/failed extractors continue from last checkpointed cursor.
- Raw JSONL appends additional pages for remaining data.

## Incremental Semantics

Incremental mode uses `hs_lastmodifieddate` with a 24-hour overlap window and prefers previous successful checkpoint high-watermarks per object. Tombstone hooks are emitted from records marked `archived` / `isDeleted`.

Each table also records schema drift metadata (`unexpected_properties`, `missing_requested_properties`) to help track object evolution, including custom objects discovered dynamically from schema metadata.

## Verification + Reconciliation

`export:verify[run_id]` checks:

- each table file exists
- extracted row count equals persisted manifest count
- checksum matches (when available)

`export:reconcile[run_id]` emits stronger row/checksum reconciliation summaries per table.

Any mismatch marks table status as `mismatch` and raises.
