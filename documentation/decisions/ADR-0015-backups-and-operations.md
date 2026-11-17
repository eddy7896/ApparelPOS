# ADR-0015: Backups, restore and downtime

- **Status:** Accepted (2026-11-17, owner)
- **Origin:** Daily backup decided by the owner; details proposed by the assistant

## Context
Biggest fears: lost sales data and downtime on a busy day. The counter database is the source of truth until it syncs.

## Decision
1. A backup of the local database is written daily to a second location (a USB drive or folder chosen by the owner) and uploaded to the cloud with each sync.
2. A restore to a clean machine is tested before go-live and after any database change.
3. The counter keeps billing when the internet is down; sync failures retry and are shown to the manager, not the cashier.
4. A written runbook covers: laptop fails, database corrupt, sync stuck.

## Alternatives considered
- **Cloud-only backup:** fails when the internet is down for days.

## Consequences
- The owner must keep the backup drive attached or connected. **Owner action.**

## Enforcement
| Rule | Check |
|---|---|
| Backup restores to a clean DB | restore test (planned) |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D6 | Backup location | USB / folder / both | **Resolved 2026-11-17 (owner): both** |
