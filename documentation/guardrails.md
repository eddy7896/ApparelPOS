# Guardrails
Status: draft for Gate 3, 2026-11-17

Purpose: limits that protect the shop's money, data and operations. Each one names its check. Checks are written at Phase 3 and are listed as planned until then.

## Biggest fears (guardrail 1)
Lost sales data, a wrong cash count, a cashier seeing cost prices, downtime on a busy day.

## 1. Data loss
- **Guardrail (ADR-0015):** a daily backup goes to two places, and a restore to a clean machine is tested before go-live.
- **Why:** the local database is the source of truth until it syncs.
- **Enforced by:** backup job and restore test (planned).
- **Verification:** E-BACKUP-1 (planned).
- **Exceptions:** none.

## 2. Cash count
- **Guardrail (SSOT 17):** the cashier's close screen shows no expected amount; variance is computed from stored sales only.
- **Why:** a visible expected amount invites a faked count.
- **Verification:** E-SHIFT-1 (planned).
- **Exceptions:** none.

## 3. Cost visibility
- **Guardrail (ADR-0003):** Sales Mode queries never select cost columns, and the local database file is encrypted.
- **Enforced by:** cashier DAOs; SQLCipher.
- **Verification:** E-AUTHZ-1, E-ENC-1 (planned).
- **Exceptions:** none.

## 4. Downtime
- **Guardrail (ADR-0008):** the counter bills with no internet; sync errors never block a sale.
- **Verification:** E-OFFLINE-1 (planned).

## 5. Authentication
- **Guardrail (ADR-0002):** PINs of exactly 6 digits and passwords are hashed with Argon2id; repeated wrong PINs lock the account. No secret is ever logged or synced.
- **Verification:** E-AUTH-1, E-AUTH-2 (planned).

## 6. Authorization
- **Guardrail (ADR-0003):** one permission matrix in `core_domain`; every operation checks it; deny by default.
- **Verification:** E-AUTHZ-2 (planned).

## 7. Money
- **Guardrail (ADR-0007):** money is integer paise; no `double` or `float` in money code.
- **Enforced by:** drift rule.
- **Verification:** E-MONEY-1 (planned).

## 8. Barcode uniqueness
- **Guardrail (ADR-0008):** a barcode value is unique (database unique index); each counter issues only from its own range.
- **Verification:** E-SERIAL-1 (planned).

## 9. Store isolation (cloud, release 2)
- **Guardrail (ADR-0001):** Firestore rules deny by default; `storeId` comes from the token.
- **Verification:** rules emulator test (planned, release 2).

## 10. Privacy
- **Guardrail (ADR-0011):** customer details are optional; bills work without them. Legal points **unverified, needs counsel**.
- **Verification:** E-PRIV-1 (planned).

## 11. Secrets
- **Guardrail (ADR-0002):** no secret, key file or `.env` in the repository; `.env.example` lists names only.
- **Verification:** secret scan in CI (planned).

## 12. Audit
- **Guardrail (ADR-0006 planned):** every write records who and when, in the same transaction.
- **Verification:** E-AUDIT-1 (planned).

## 13. AI agent safety
- **Guardrail:** an agent never pushes to protected branches, never changes security rules or guardrails without an ADR, and never weakens a check to pass it.
- **Verification:** branch protection (owner action); review checklist.

## 14. Scope
- **Guardrail:** out of scope for release 1: loyalty, promos, card/UPI terminals, WhatsApp receipts, supplier payout ledger, multi-shop, Android counters, mobile app.
- **Verification:** review checklist.
