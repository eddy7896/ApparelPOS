# ADR-0002: Identity and authentication

- **Status:** Accepted (2026-11-17, owner)
- **Builds on:** ADR-0001
- **Origin:** Proposed by the assistant

## Context
Counters must sign in with no internet. The owner's phone needs a cloud identity. The spec uses PIN and password on the counter.

## Decision
1. On the counter, users sign in with a PIN of at least 6 digits (cashier) or a password (manager/owner), checked against salted hashes in the local database (Argon2id, not plain SHA-256). The 6-digit minimum was decided by the owner on 2026-11-17.
2. The manager mobile app and each counter device sign in to Firebase Authentication; the token carries `storeId` and `role` as custom claims set only by a trusted server-side step.
3. No password or PIN is ever stored in plain text, logged, or synced.
4. Repeated wrong PINs lock the account for a delay set in configuration. Owner decisions, 2026-11-20: a cashier picks their name from a list, then types the PIN; 5 wrong tries lock that account for 5 minutes, each later lockout doubles up to 1 hour, and a correct sign-in clears it; the settings are meant to become owner-editable (not built yet). A locked account is not checked at all, so guessing during a lock does nothing and does not extend it.
5. The manager and owner password has at least 10 characters (length only, counted in characters; no other rule; owner, 2026-11-20). PINs are 6 to 12 digits; no rule against easy PINs such as 123456 (not asked; the owner may want one).
6. The counter locks itself after 5 idle minutes and on Ctrl+L (owner, 2026-11-20). The rule is built in `core_domain`; the screen that uses it is the next task.
7. New hashes use Argon2id with 19 MiB memory, 2 passes, 1 lane (the OWASP minimum, the assistant's choice; about 65 ms on a Mac, unverified on the shop laptop). The settings are stored inside each hash, so they can be raised later and old hashes still verify and are re-hashed at the next correct sign-in. The hashing library is `hashlib` 2.4.3 (pure Dart), checked against the RFC 9106 Argon2id test vector.
8a. First launch (no users): an install wizard asks for the owner's name and a password (twice) and signs them in; it cannot run again once any user exists (ADR-0002 D1). Cashiers are added later by the owner in Manager Mode (not built).
8b. After sign-in a cashier sees Sales Mode and a manager or owner sees Manager Mode; both are empty shells until billing, stock and reports are built.
8. Sign-in events (success, lockout) go to the audit log on this device only; they are not queued for the cloud. Secrets, hashes and wrong guesses are never logged.

## Alternatives considered
- **SHA-256 for PINs (spec):** PINs are short, so fast hashes are easy to brute-force; rejected.
- **Cloud-only login:** breaks offline billing.

## Consequences
- Setting custom claims needs a small Cloud Function (Firebase Blaze plan). **Unverified:** Firebase pricing and plan limits at build time.

## Enforcement
| Rule | Check |
|---|---|
| PINs and passwords hashed with Argon2id; PIN 6+ digits; lockout works and survives restart | E-AUTH-1, E-AUTH-2: `packages/core_domain/test/auth_rules_test.dart`, `credential_hasher_test.dart`, `apps/pos_windows/test/data/auth_service_test.dart` |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D1 | Who sets the first owner password | Install wizard | **Built in P2-2** |
