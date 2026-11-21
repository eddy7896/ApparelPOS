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
- Adds SQLCipher to the build.
- **Amended 2026-11-21 (P3-1, owner chose the recovery key and one Windows login; the library choices are the assistant's):**
  7. SQLCipher comes through `package:sqlite3`'s build hook (`hooks: user_defines: sqlite3: source: sqlcipher` in `apps/pos_windows/pubspec.yaml`), not through `sqlcipher_flutter_libs` (end of life). The binary is a third-party build downloaded from the sqlite3.dart GitHub releases at build time and checked against SHA-256 hashes pinned inside `package:sqlite3` 3.9.1. It links OpenSSL on Windows. Licence terms of SQLCipher community edition are unverified here.
  8. The key is 32 random bytes made on first launch, opened as a raw key, and kept in the Windows credential store through `flutter_secure_storage` (Windows backend 4.2.2). It is never written to the database, audit log, outbox or repository.
  9. The app checks at start-up that the build really is SQLCipher (`PRAGMA cipher_version`) and refuses to start otherwise; it never replaces an existing database with a new empty one if the key is missing (it stops with a clear message); a plain-text database from an earlier development build is converted in place and its plain-text copy deleted.
  10. **Recovery key (owner, 2026-11-21):** the same key is shown once to the owner or manager as 16 groups of 4 hex digits plus a check group; they write it down and type the last group back before carrying on. With it and a backup, the database can be opened on a new computer. Lose both the key and the computer and the data is gone. The owner and cashiers are assumed to share one Windows login on the counter laptop (owner, 2026-11-21); with separate logins the key store would not be shared.
  11. The browser preview is not encrypted and keeps nothing (ADR-0016).
- **Unverified:** that Windows loads `sqlcipher.dll` and the credential store works on a real machine (only a CI build and tests on this Mac and the CI runner have run); SQLCipher licence; the speed of an encrypted database on the shop laptop.

## Enforcement
| Rule | Check |
|---|---|
| Cashier DAOs return no cost fields | unit tests (planned) |
| Database file unreadable without the key (E-ENC-1) | `apps/pos_windows/test/data/encrypted_connection_test.dart` (real files, real SQLCipher) |
| Recovery key shown once, never stored | `recovery_key_repository_test.dart`, `recovery_key_screen_test.dart`, `packages/core_domain/test/recovery_key_test.dart` |
| Permission matrix tested | E-AUTHZ-2: `packages/core_domain/test/permissions_test.dart` |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D2 | Encrypt local DB | yes / no | **Resolved 2026-11-17 (owner): yes** |
