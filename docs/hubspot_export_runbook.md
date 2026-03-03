# HubSpot Export Runbook

## 1) Preflight

1. Ensure credentials are set (`COMPOSIO_API_KEY`, `COMPOSIO_CONNECTED_ACCOUNT_ID`).
2. Ensure DB migrations are applied.
3. Ensure disk path `exports/` is writable.
4. Run a connectivity smoke test before long backfills:
   - `bin/rails runner 'puts Hubspot::Client.default.execute_action("HUBSPOT_HUBSPOT_LIST_OWNERS", {}).keys'`

## 2) Execute Full Dump

1. `bin/rails "export:full_dump[portal_id]"`
2. Capture returned `run_id` from command output.
3. Confirm status:
   - `bin/rails runner 'puts ExportRun.find_by!(run_id: "<RUN_ID>").status'`

## 3) Resume Failed Run

1. Identify failed run:
   - `bin/rails runner 'p ExportRun.where(status: [:failed, :retry_exhausted]).order(created_at: :desc).limit(5).pluck(:run_id, :status, :error_message)'`
2. Resume:
   - `bin/rails "export:resume[run_id]"`

## 4) Verify + Reconcile Output

1. `bin/rails "export:verify[run_id]"`
2. `bin/rails "export:reconcile[run_id]"`
3. Inspect generated artifacts:
   - `exports/run_id=<RUN_ID>/manifests/verification_report.json`
   - `exports/run_id=<RUN_ID>/manifests/reconciliation_report.json`
   - `exports/run_id=<RUN_ID>/manifests/coverage_matrix.md`
4. Reconciliation now also reports:
   - duplicate `_record_id` count per JSONL table
   - invalid JSON line count per JSONL table

## 5) Coverage Audit

- Generate matrix in terminal:
  - `bin/rails "export:coverage[run_id]"`
- Expected statuses:
  - `FULL` = table exported with rows
  - `PARTIAL` = extractor ran but no rows (or duplicate rows detected in reconciliation)
  - `BLOCKED` = extractor missing or unavailable in this run

## 6) Associations Labels Metadata

- Each associations extractor writes a companion metadata snapshot:
  - `exports/run_id=<RUN_ID>/metadata/associations/<source_object>.json`
- This file includes label/category/type-id rollups by target object.
- Use it to map association semantics before loading to downstream dimensional tables.

## 7) Custom Objects + Schema Drift

- Custom object schemas are discovered from `metadata/schemas/schemas.json`.
- Dynamic extractors include schema properties when present.
- Drift signals are emitted in each table metadata:
  - `metadata.schema_drift.unexpected_properties`
  - `metadata.schema_drift.missing_requested_properties`
- Operational action when drift appears:
  1. confirm schema change in HubSpot,
  2. run a fresh full dump for impacted objects,
  3. update downstream model contracts.

## 8) Deletions / Recycle-bin Fallback

- Current deletion strategy relies on `record.archived` and `record.isDeleted` flags in object payloads.
- Table metadata explicitly records recycle-bin adapter fallback status.
- If hard deletion evidence is required, treat this export as `soft-delete aware` and schedule a manual API validation until recycle-bin adapter actions are available in Composio.

## 9) Investigate Common Issues

- `Missing COMPOSIO_API_KEY`:
  - set ENV var or Rails credentials key `composio.api_key`
- `Missing COMPOSIO_CONNECTED_ACCOUNT_ID`:
  - set ENV var or credentials key `composio.connected_account_id`
- repeated `retry_exhausted`:
  - inspect `export_runs.error_message`
  - inspect API rate limits; reduce concurrent external usage
- association extractor warnings:
  - check `export_checkpoints.metadata.by_target`
  - inspect `metadata/associations/*.json` for missing labels/categories
- schema drift spikes:
  - inspect `tables_manifest.json` metadata for affected extractors
  - align downstream schemas before incremental runs

## 10) Operational Notes

- `export:verify` and `export:reconcile` are safe and idempotent.
- `export:resume` is idempotent for completed checkpoints.
- run manifests are regenerated at the end of successful run execution.
- keep at least one recent successful `full_dump` per portal for baseline reconciliation.
