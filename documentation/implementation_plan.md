# Implementation plan
Status: draft for Gate 3, 2026-11-17

Purpose: phases and task IDs. Size S <= 1 day, M <= 3 days, L <= 1 week. Phases have goals, not dates.

## Phases
| Phase | Goal |
|---|---|
| P0 | Foundation: repo, documents, checks, branching, app skeletons |
| P1 | Core domain: money, pricing, barcodes, permissions, with tests |
| P2 | Counter app release 1: stock entry, labels, billing, returns, cash close |
| P3 | Go-live hardening: encryption, backups, restore, install |
| P4 | Sync and manager mobile app (release 2) |

## P0 foundation
| ID | Task | Size | Acceptance | Depends on | Status |
|---|---|---|---|---|---|
| P0-1 | Repo and workspace tooling | S | `AGENTS.md` commands run | Gate 5 | done |
| P0-2 | Documents and ADRs | M | Gate 3 passed | Gate 2 | done |
| P0-3 | Drift check, evals, golden set | M | Gate 4 green | P0-2 | done |
| P0-4 | Branching, CI, PR template | S | Gate 5 | P0-3 | done |
| P0-5 | Skeletons for `pos_windows`, `core_domain` that build and test | M | builds on Windows (unverified) | P0-4 | done |

## P1 core domain
| ID | Task | Size | Acceptance | Depends on | Status |
|---|---|---|---|---|---|
| P1-1 | Money type and rounding in paise | S | E-MONEY-1 | P0-5 | done |
| P1-2 | Barcode encoder and serial ranges | M | E-SERIAL-1 | P1-1 | done |
| P1-3 | Pricing engine (MRP, markdown) | M | unit tests | P1-1 | done |
| P1-4 | Permission matrix | S | E-AUTHZ-2 | P0-5 | done |
| P1-5 | Hangtag geometry, rupee text and Code 128C encoder | M | cell geometry tests; oracle-checked encoder | P1-2 | done |
| P1-5b | PDF drawing: embed a font with the rupee sign, draw bars and text | M | PDF opens and scans; font licence verified | P1-5 | done |

## P2 counter app
| ID | Task | Size | Acceptance | Depends on | Status |
|---|---|---|---|---|---|
| P2-1 | Drift tables, WAL, migrations | M | E-SERIAL-1 | P1 | done |
| P2-2 | Lock screen, auth, idle lock | M | E-AUTH-1, 2 | P2-1 | done |
| P2-3a | Purchase rules, save in one transaction, size and color lists, label data | M | stock tests | P2-1, P1-5 | done |
| P2-3b | Stock entry screen (Size x Color grid) and label printing | L | screen tests; a printed sheet scans | P2-3a, P2-2 | done |
| P2-4a | Bill rules: bill number (year/counter/serial), payments (cash, UPI, card, split), change | S | unit tests; mutation-checked | P1 | done |
| P2-4b | Sales tables, safe stock lookup for cashiers (no cost columns), save a bill in one transaction (E-SALE-1) | L | E-SALE-1, E-AUTHZ-1 | P2-4a | done |
| P2-4c | Register screen: scan, bill lines, discount, pay, on-screen bill and PDF print | L | E-OFFLINE-1; screen tests | P2-4b | done |
| P2-4e | Markdown at the register (manager or owner sets a percent or amount markdown on a garment) | S | owner picks percent or amount each time; screen tests | P2-4c | todo |
| P2-4d | Pay later (udhaar): customer records, balance owed, later payments | L | owner chose 2026-11-20; questions needed first | P2-4c | todo |
| P2-5a | Return rules: window, refund total, refund modes, credit note code, expiry and balance | S | unit tests; mutation-checked | P2-4a | done |
| P2-5b | Return and credit note tables, save a return in one transaction (restock or damaged), use a credit note on a bill, exchange | L | E-RETURN-1, E-SALE-1, E-AUDIT-1 | P2-5a, P2-4c | doing |
| P2-5c | Returns screen, credit note slip print, credit note at the register | L | screen tests | P2-5b | todo |
| P2-6 | Blind shift close and daybook | M | E-SHIFT-1 | P2-4 | todo |
| P2-7 | Owner reports (daily) | M | totals match daybook | P2-6 | todo |

## P3 go-live
| ID | Task | Size | Acceptance | Depends on | Status |
|---|---|---|---|---|---|
| P3-1 | SQLCipher encryption spike and rollout | M | E-ENC-1 | P2-1 | todo |
| P3-2 | Daily backup and restore test | M | E-BACKUP-1 | P3-1 | todo |
| P3-3 | Installer and runbook | M | owner can install | P3-2 | todo |
| P3-4 | GST toggle scaffold (settings, tax fields) | M | E-GST-1 | P2-4 | todo |

## P4 release 2
Sync engine, Firestore rules, manager mobile app, counter setup (count and per-counter settings), second counter support. Tasks are split when P3 closes.

## Owner decisions needed
| ID | Question | Options | Recommended |
|---|---|---|---|
| D3c | GST invoice fields and reports | **Resolved 2026-11-17 (owner): open catalogue the owner toggles at GST setup** | n/a |
| Q1 | Accessibility and performance targets | owner's call | **Resolved 2026-11-17 (owner): 48dp click targets; a bill saves in under 1 second** |
| Q2 | Shop hardware (scanner, printers) | owner will tell us once chosen | **Decided 2026-11-17: the shop has none yet. The app supports normal A4 printers and thermal receipt printers; the exact models come later** |
