# HubSpot Export Runbook

## 1) Preflight

1. Ensure credentials are set (`COMPOSIO_API_KEY`, `COMPOSIO_CONNECTED_ACCOUNT_ID`).
2. Ensure DB migrations are applied.
3. Ensure disk path `exports/` is writable.

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

## 5) Coverage Audit

- Generate matrix in terminal:
  - `bin/rails "export:coverage[run_id]"`
- Expected statuses:
  - `FULL` = table exported with rows
  - `PARTIAL` = extractor ran but no rows
  - `BLOCKED` = extractor missing or unavailable in this run

## 6) Investigate Common Issues

- `Missing COMPOSIO_API_KEY`:
  - set ENV var or Rails credentials key `composio.api_key`
- `Missing COMPOSIO_CONNECTED_ACCOUNT_ID`:
  - set ENV var or credentials key `composio.connected_account_id`
- repeated `retry_exhausted`:
  - inspect `export_runs.error_message`
  - inspect API rate limits; reduce concurrent external usage
- association extractor warnings:
  - check `export_checkpoints.metadata.by_target`
  - verify Composio association action availability in your tenant

## 7) Operational Notes

- `export:verify` and `export:reconcile` are safe and idempotent.
- `export:resume` is idempotent for completed checkpoints.
- run manifests are regenerated at the end of successful run execution.
