# ADR-0006: Data model rules and audit

- **Status:** Proposed
- **Builds on:** ADR-0007, ADR-0008
- **Origin:** Proposed by the assistant

## Context
Audit is required for every write. Several counters will later write independently.

## Decision
1. Primary keys are UUIDs (v4 or v7) generated on the device, so counters never collide.
2. Every row has `created_at` and `updated_at` in UTC, plus `created_by` where a user acted.
3. Sales, returns and daybook rows are never edited or deleted; a mistake is corrected by a reversing row.
4. The audit row (who, when, what) and the outbox row are written in the same transaction as the change.
5. Every schema change ships with a Drift migration and a migration test.
6. `barcode_value` has a unique index.

## Alternatives considered
- **Auto-increment integer ids:** collide across counters.

## Consequences
- Slightly larger keys; safe merging later.

## Enforcement
| Rule | Check |
|---|---|
| Audit written with the change | E-AUDIT-1 (planned) |
| Barcode unique | E-SERIAL-1 (planned) |

## Open decisions
None.
