# HubSpot Full Dump Master Plan (Super Ambitious)

## Goal
Build a **reliable, resumable, auditable, near-complete exporter** for HubSpot so you can reconstruct your full HubSpot state later in any warehouse/lake/tooling stack.

Success = you can run one command/schedule and get:
- historical full backfill,
- incremental updates,
- files + metadata + associations + timelines,
- repeatable checks proving coverage and integrity.

---

## North-Star Principles
1. **Completeness over convenience**: prioritize broad object coverage first, then optimize.
2. **Exactly-once-at-rest**: duplicates tolerated in transit, deduped deterministically on write.
3. **Resumability everywhere**: every fetch must restart from checkpoints.
4. **Schema evolution by design**: handle new/removed fields without breaking pipeline.
5. **Observable + provable**: every run emits quality metrics and a verification report.
6. **Portable output**: Parquet + JSONL + manifest for future-proof analytics.

---

## Scope (Target Data Domains)

### Core CRM
- Contacts
- Companies
- Deals
- Tickets
- Leads
- Products
- Line items
- Quotes
- Calls
- Emails
- Meetings
- Notes
- Tasks
- Custom objects (all discovered dynamically)

### Relationships
- Full object associations (all association types/labels)
- Parent-child graphs for custom object relationships

### History / Timeline
- Property history where available
- Engagement timelines / activities
- Owners and pipelines/stages snapshots

### Metadata / Config
- Property definitions per object
- Pipeline definitions/stages
- Owners/users
- Custom object schemas
- Association labels/types

### Optional Advanced Domains (Phase 2+)
- Marketing events
- Forms/submissions
- Lists/memberships
- Emails/campaign performance
- Conversations/inbox exports

> Design note: maintain a `coverage matrix` to explicitly track which domains are fully exported, partial, or pending.

---

## Export Contract (Output Format)

## Directory layout
```text
exports/
  run_id=2026-03-02T23-59-59Z/
    manifests/
      run_manifest.json
      tables_manifest.json
      checksum_manifest.json
    crm/
      object=contacts/part-*.parquet
      object=contacts_history/part-*.parquet
      object=contacts_associations/part-*.parquet
      ...
    metadata/
      properties/*.json
      pipelines/*.json
      owners/*.json
      schemas/*.json
    raw_jsonl/
      endpoint=.../*.jsonl.gz
```

## Table-level standard columns
- `_hs_portal_id`
- `_object_type`
- `_record_id`
- `_extracted_at`
- `_cursor` / `_page_token`
- `_source_endpoint`
- `_run_id`
- `_raw_hash`
- `_deleted` (if known)
- `_valid_from` / `_valid_to` (for SCD2 style history where applied)

## Manifest fields
- run id, started/finished timestamps
- portal id
- api app id/version
- object counts expected vs extracted vs loaded
- endpoint-level retries/throttling stats
- checksum/hash summaries
- verification status

---

## Reliability Architecture

## 1) Orchestrator
- Job graph per domain (metadata first, then objects, then associations/history)
- Idempotent jobs keyed by `(portal, object, partition, cursor)`
- Persisted state machine: queued/running/succeeded/failed/retry_exhausted

## 2) Checkpoint Store
- Cursor/timestamp checkpoints per extractor
- High-water marks per object type
- Retry counters + dead-letter queue for poison pages

## 3) Fetch Engine
- Adaptive rate-limit handling (429-aware with jittered exponential backoff)
- Concurrency caps by endpoint family
- Circuit breaker when sustained failures occur
- Automatic token refresh hooks / auth validation preflight

## 4) Storage Writer
- Write raw + normalized in parallel
- Atomic file finalize (temp then commit)
- Deterministic dedupe key (`record_id + updated_at + hash`)

## 5) Validator
- Count reconciliation against search/list totals where possible
- Referential checks (associations point to known ids)
- Null/shape anomaly detection by object profile

---

## Extraction Strategy

## A. Bootstrap Full Backfill
1. Pull metadata definitions (properties/schemas/pipelines/owners).
2. Enumerate all standard + custom objects.
3. Backfill object records page-by-page.
4. Backfill associations separately (fan-out by object id batches).
5. Backfill history/timeline endpoints.
6. Generate reconciliation report and freeze `baseline snapshot`.

## B. Incremental Sync
- Primary cursor: `hs_lastmodifieddate` (or endpoint equivalent)
- Sliding overlap window (e.g., re-read last 24h) to catch late updates
- Tombstone/deletion handling strategy per object
- Daily compaction + dedupe into gold tables

## C. Reconciliation Loops
- Daily light reconciliation (counts + key spot checks)
- Weekly deep reconciliation (sampled payload hash compare)
- Monthly full drift audit (schema + volume + relationship integrity)

---

## Completeness & Trust Framework

## Coverage Matrix (must-have artifact)
For each domain/object:
- endpoint used
- fields included
- history available?
- associations available?
- deletion signal available?
- current status: `FULL | PARTIAL | BLOCKED`
- blocker reason / next action

## Data Quality SLAs
- Export success rate: >99.5%
- Missing-page incidents: 0 tolerated (must fail run)
- Duplicate ratio post-dedupe: <0.1%
- Reconciliation mismatch threshold: <0.5% (or hard fail above)

## Verification Report per run
- total rows per table
- changed rows since previous run
- schema changes detected
- endpoint failures/retries
- top anomalies and likely causes

---

## Security & Compliance
- Credentials only via env/secret manager (never repo)
- PII-aware classification tags in manifest
- Optional field-level redaction/encryption policy
- Audit log of who triggered exports and where artifacts were delivered
- At-rest encryption for all dumps + signed checksums

---

## Implementation Roadmap

## Phase 0 — Foundations (Week 1)
- Export config model + portal config
- Job orchestration skeleton
- Checkpoint + manifest store
- Retry/backoff middleware

## Phase 1 — Core Full Dump MVP (Weeks 2–3)
- Contacts/Companies/Deals/Tickets + metadata
- Raw JSONL + normalized Parquet
- Run manifest + counts reconciliation
- Manual CLI trigger and resumable restarts

## Phase 2 — Full CRM Graph (Weeks 4–5)
- All standard objects + custom objects discovery
- Associations exporter
- Pipeline/owners/property snapshots
- Coverage matrix autogenerated

## Phase 3 — History, Drift, and Hardening (Weeks 6–7)
- Property history / activity timeline ingestion
- Deep validation suite
- Dedupe + compaction jobs
- Alerting and SLO dashboards

## Phase 4 — Production-grade Ops (Week 8)
- Scheduled incremental sync
- Recovery playbooks + DLQ tooling
- Cost/perf tuning
- One-command “disaster restore export” simulation

---

## Tech Decisions (Recommended)
- **Runtime**: Ruby jobs integrated with Rails app
- **Queue**: ActiveJob + Solid Queue (or Sidekiq if already standardized)
- **Storage**: S3-compatible bucket + local fallback
- **Formats**: JSONL (raw), Parquet (analytics), manifest JSON
- **Validation**: Great Expectations-style checks (or custom validator service)
- **Observability**: structured logs + metrics + alerting hooks

---

## Concrete Deliverables
1. `Export::Run` domain model (state, timings, status)
2. Object extractor framework with endpoint adapters
3. Association extractor framework
4. Checkpoint repository abstraction
5. Manifest generator
6. Validation engine + reconciliation report
7. CLI commands:
   - `export:full_dump[portal_id]`
   - `export:incremental[portal_id]`
   - `export:resume[run_id]`
   - `export:verify[run_id]`
8. Coverage matrix markdown/json generated per release
9. Incident/runbook docs

---

## Stretch Goals (Ultra Ambitious)
- Multi-portal concurrent export coordinator
- “Time-travel replay” dataset snapshots
- Automatic schema migration proposals when HubSpot adds fields
- Deterministic restore toolkit: recreate object graph in a target system
- Continuous contract tests against sandbox HubSpot portals

---

## First 10 Tasks to Execute Now
1. Define canonical object registry (`standard + custom dynamic`).
2. Implement auth preflight + rate-limit policy module.
3. Create run/checkpoint tables in DB.
4. Build extractor interface (`fetch_page`, `normalize`, `checkpoint_key`).
5. Ship contacts extractor end-to-end with manifest.
6. Add companies/deals extractors reusing same framework.
7. Add associations exporter (batch by source ids).
8. Implement reconciliation counts by object.
9. Add resumable CLI commands.
10. Add run report markdown generation under `exports/run_id=.../manifests`.

---

If we execute this plan, you’ll have a **serious, enterprise-grade HubSpot dump pipeline** that is dependable enough for migrations, analytics, archiving, and recovery workflows.