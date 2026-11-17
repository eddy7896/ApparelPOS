# ADR-0003: Authorization model

- **Status:** Accepted (2026-11-17, owner)
- **Builds on:** ADR-0002
- **Origin:** Proposed by the assistant

## Context
Walls: the cashier never sees cost prices, margins, procurement or daybook history. The cashier and owner share one local database file on the counter laptop.

## Decision
1. Roles are `CASHIER`, `MANAGER`, `OWNER`; a permission matrix lives in `core_domain` as code and is the only source of truth.
2. Every screen and every data-access function checks the matrix; deny by default.
3. Sales Mode queries use views or DAOs that never select cost columns, so cost data is not loaded in cashier sessions.
4. The local database file is encrypted at rest (SQLCipher) with a key kept in the Windows credential store, so a cashier with file access cannot read cost prices.
5. A discount above the cashier's limit needs the manager's password.

## Alternatives considered
- **UI hiding only:** a cashier who opens the file could read costs; rejected.
- **Separate databases for cost data:** heavier; revisit if encryption proves insufficient.

## Consequences
- Adds SQLCipher to the build. **Unverified:** compatibility with Drift on Windows; spike first.

## Enforcement
| Rule | Check |
|---|---|
| Cashier DAOs return no cost fields | unit tests (planned) |
| Permission matrix tested | tests (planned) |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D2 | Encrypt local DB | yes / no | **Resolved 2026-11-17 (owner): yes** |
