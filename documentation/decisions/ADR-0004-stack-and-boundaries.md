# ADR-0004: Stack and boundaries

- **Status:** Accepted (2026-11-17, owner)
- **Origin:** Proposed by the assistant (stack from the owner's spec; Firebase confirmed by the owner)

## Context
Solo builder; fewest moving parts. Later counters may be Android tablets.

## Decision
1. Flutter/Dart monorepo (Melos or Dart workspace): `core_domain`, `sync_engine`, `pos_windows`, `manager_mobile`.
2. Local database: SQLite through Drift in WAL mode. Cloud: Cloud Firestore and Firebase Authentication.
3. Business rules (pricing, serials, returns) live only in `core_domain`; apps do not duplicate them.
4. Apps talk to Firestore only through `sync_engine`.
5. Banned for now: a custom backend server, real-time per-scan streaming, floating-point money.

## Alternatives considered
- **Electron/web POS:** more moving parts for offline hardware access.
- **Own server and Postgres:** more operations work for a solo builder.

## Consequences
- Windows app and later Android tablet share most code. **Unverified:** current package versions and Drift/Windows behaviour; verify at project setup.

## Enforcement
| Rule | Check |
|---|---|
| No Firestore import outside `sync_engine` | drift check (planned) |

## Open decisions
None.
