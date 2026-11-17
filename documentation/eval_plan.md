# Eval plan
Status: draft for Gate 3, 2026-11-17

Purpose: which checks exist, when they run, and the rules for changing them. All are Planned; nothing runs yet.

## Layers
| Layer | What | Status |
|---|---|---|
| Unit | Pricing, money, barcodes, permissions (`core_domain`) | Phase 1 |
| Database | Drift tables, unique barcode, cost-column exclusion, encryption | Phase 2 |
| Drift check | Docs vs code, banned imports, float money | Phase 3 |
| Golden set | Hallucination questions | Phase 3 |
| Restore test | Backup to clean DB | Phase 3 |
| Widget/integration | Billing, returns, cash close flows | Phase 2 |
| Branch policy | CI check | Phase 4 |

## Eval catalogue (IDs reserved)
| ID | What it proves |
|---|---|
| E-MONEY-1 | No floating-point money; rounding function exact |
| E-SERIAL-1 | Barcodes unique across counters; ranges never overlap |
| E-AUTH-1 | PIN needs 6+ digits and is hashed with Argon2id |
| E-AUTH-2 | Lockout after repeated wrong PINs |
| E-AUTHZ-1 | Cashier queries return no cost fields |
| E-AUTHZ-2 | Permission matrix denies by default |
| E-ENC-1 | Database file is unreadable without the key |
| E-SALE-1 | Same barcode cannot be sold twice |
| E-RETURN-1 | Return refunds exact net price and tax |
| E-SHIFT-1 | Blind close shows no expected amount; variance correct |
| E-OFFLINE-1 | A sale completes with no network |
| E-BACKUP-1 | Backup restores to a clean database |
| E-PRIV-1 | A bill completes with no customer details |
| E-AUDIT-1 | Every write has user and time |
| E-GST-1 | GST off by default; enabling does not alter past bills |

## Cadence
Every pull request: unit, database, drift, branch policy. Monthly and after document changes: golden set. At each gate: everything. Before go-live: restore test.

## Rules
Never loosen an eval without an ADR. Every hallucination seen becomes a golden item and, if mechanical, a drift rule.
