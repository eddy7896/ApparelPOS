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
5. A discount above the cashier's limit needs the manager's password. The limit is 10% of the item price by default (owner, 2026-11-18) and is meant to be an owner setting (the setting itself is not built yet). Percent discounts are compared in basis points; fixed amounts by exact integer comparison against the price.
6. Cashier permissions (owner, 2026-11-18): sell, print bills, take returns, close own shift, look up stock and prices, give discounts up to the limit. Everything else is denied. MANAGER has every permission, the same as OWNER, because they are the same person today; the matrix keeps the roles separate so they can diverge later. The full list is in `documentation/modules/auth_and_roles.md`.

## Alternatives considered
- **UI hiding only:** a cashier who opens the file could read costs; rejected.
- **Separate databases for cost data:** heavier; revisit if encryption proves insufficient.

## Consequences
- Adds SQLCipher to the build. **Unverified:** compatibility with Drift on Windows; spike first.

## Enforcement
| Rule | Check |
|---|---|
| Cashier DAOs return no cost fields | unit tests (planned) |
| Permission matrix tested | E-AUTHZ-2: `packages/core_domain/test/permissions_test.dart` |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D2 | Encrypt local DB | yes / no | **Resolved 2026-11-17 (owner): yes** |
