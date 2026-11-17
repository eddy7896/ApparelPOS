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
4. Repeated wrong PINs lock the account for a delay set in configuration.

## Alternatives considered
- **SHA-256 for PINs (spec):** PINs are short, so fast hashes are easy to brute-force; rejected.
- **Cloud-only login:** breaks offline billing.

## Consequences
- Setting custom claims needs a small Cloud Function (Firebase Blaze plan). **Unverified:** Firebase pricing and plan limits at build time.

## Enforcement
| Rule | Check |
|---|---|
| PINs hashed with Argon2id, lockout works | unit tests (planned) |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D1 | Who sets the first owner password | Install wizard | Install wizard (recommended taken) |
