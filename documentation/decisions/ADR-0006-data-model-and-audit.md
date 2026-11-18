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
7. The barcode is 12 digits: YYMM + 3-digit lot + 4-digit serial + a check digit. The owner approved the check digit on 2026-11-18 because Code 128 Subset C encodes digit pairs and the original 11 digits is odd. The Luhn algorithm is the assistant's pick; please confirm.
8. Counters are kept apart by lot number: each counter owns a range of lots (for example 000-499 and 500-999) and issues serials 0000-9999 inside its current lot, one lot at a time. Ranges must never overlap (owner chose this, 2026-11-18). Who assigns ranges, and how they are stored, is not yet decided (P2-1).

## Alternatives considered
- **Auto-increment integer ids:** collide across counters.

## Consequences
- Slightly larger keys; safe merging later.

## Enforcement
| Rule | Check |
|---|---|
| Audit written with the change | E-AUDIT-1 (planned) |
| Barcode unique | E-SERIAL-1: `packages/core_domain/test/barcode_test.dart` (the database unique index is planned, P2-1) |

## Open decisions
None.
