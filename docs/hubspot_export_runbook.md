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

## 4) Verify Output

1. `bin/rails "export:verify[run_id]"`
2. Inspect `exports/run_id=<RUN_ID>/manifests/verification_report.json`.

## 5) Investigate Common Issues

- `Missing COMPOSIO_API_KEY`:
  - set ENV var or Rails credentials key `composio.api_key`
- `Missing COMPOSIO_CONNECTED_ACCOUNT_ID`:
  - set ENV var or credentials key `composio.connected_account_id`
- repeated `retry_exhausted`:
  - inspect `export_runs.error_message`
  - inspect API rate limits; reduce concurrent external usage

## 6) Operational Notes

- `export:verify` is safe and idempotent.
- `export:resume` is idempotent for completed checkpoints.
- run manifests are regenerated at the end of successful run execution.

