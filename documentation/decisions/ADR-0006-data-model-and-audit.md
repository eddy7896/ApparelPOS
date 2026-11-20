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
9. Each garment (article) keeps its own MRP, saved when its tag is printed; changing a style's MRP later does not change garments already in stock (owner, 2026-11-20).
10. Cost columns live only in `batch_lines` so cashier code can be kept away from one table (E-AUTHZ-1 is enforced when the cashier data layer is built, not by the schema alone).
11. The local database uses write-ahead logging (WAL) and foreign keys, stores times as UTC, and refuses to open a database made by a newer app version.
12. Release-1 tables: schema version 1 has `counters`, `products`, `variants`, `batches`, `batch_lines`, `articles`, `audit_log`, `outbox`; version 2 adds `users` (P2-2). Each version has a migration test (`apps/pos_windows/test/data/migration_test.dart`). Sales, returns, shifts and daybook tables come with their tasks, each with a migration. The database is **not encrypted yet** (SQLCipher is P3-1, E-ENC-1 pending).

13. Schema version 3 adds `app_settings` (shop name), `size_options` and `color_options` (the lists offered in the purchase grid; names are unique ignoring case). Sizes and colors on variants stay plain text.
14. Counter 1 is created once with lots 000-499 at lot 0, serial 0; lots 500-999 stay free for a second counter (owner, 2026-11-20). Who assigns a second counter's range is still undecided.
15. Saving a purchase writes the style, variants, batch, costs, every article, the counter's new position, one audit row and one outbox row in one transaction. Costs are not written to the audit or outbox details.

## Alternatives considered
- **Auto-increment integer ids:** collide across counters.

## Consequences
- Slightly larger keys; safe merging later.

## Enforcement
| Rule | Check |
|---|---|
| Audit and outbox written with the change | E-AUDIT-1: `apps/pos_windows/test/data/app_database_test.dart` (`AuditedWriter`) |
| Barcode unique, 12 digits; valid status; MRP and cost not negative; foreign keys on; WAL | same test file |
| Barcode unique | E-SERIAL-1: `packages/core_domain/test/barcode_test.dart` (the database unique index is planned, P2-1) |

## Open decisions
None.
