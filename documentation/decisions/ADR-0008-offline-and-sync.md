# ADR-0008: Offline-first counters and cloud sync

- **Status:** Accepted (2026-11-17, owner)
- **Builds on:** ADR-0001, ADR-0004
- **Origin:** Counter design decided by the owner (own local DB per counter, cloud sync); serial ranges and double-sale rule accepted by the owner 2026-11-17

## Context
Each counter keeps its own local database. One counter for at least two years; more later. Shop must keep billing with no internet.

## Decision
1. Every write commits locally first, with an outbox row in the same transaction.
2. Sync runs every 15 minutes, at shift close and on "Sync Now"; pushes compact deltas and daily summaries.
3. Each counter has a `counterId`. Barcode serial ranges are reserved per counter (for example, a counter leases a block of lots), so two counters never issue the same barcode.
4. If the same barcode is sold on two counters offline, the earlier sale (by recorded time) wins and the other is flagged to the owner as an exception to fix.
5. Remote commands (markdown, PIN change, theme) are applied by the counter on its next pull and marked applied; a command is idempotent.
6. Article sync is range-compressed (`serial_start..serial_end` plus sold/returned arrays); no per-garment cloud documents.
7. A nightly local backup is written and a restore is tested (ADR-0015).

## Alternatives considered
- **One main counter holding the database:** simpler, but rejected by the owner.
- **Real-time streaming per scan:** cost and complexity.

## Consequences
- Conflicts are possible only with 2+ counters, and are surfaced, not silently resolved.
- Counter clocks can differ: **unverified**; record device time and server receive time, and flag large skew.

## Enforcement
| Rule | Check |
|---|---|
| Two counters never issue the same barcode | unit and property tests (planned) |
| Double sale detected | sync test (planned) |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D4 | Range block size per counter | 1 lot / fixed count | **Resolved 2026-11-17 (owner): 1 lot** |
