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
| P0-1 | Repo and workspace tooling | S | `AGENTS.md` commands run | Gate 5 | todo |
| P0-2 | Documents and ADRs | M | Gate 3 passed | Gate 2 | done |
| P0-3 | Drift check, evals, golden set | M | Gate 4 green | P0-2 | done |
| P0-4 | Branching, CI, PR template | S | Gate 5 | P0-3 | todo |
| P0-5 | Skeletons for `pos_windows`, `core_domain` that build and test | M | builds on Windows (unverified) | P0-4 | todo |

## P1 core domain
| ID | Task | Size | Acceptance | Depends on | Status |
|---|---|---|---|---|---|
| P1-1 | Money type and rounding in paise | S | E-MONEY-1 | P0-5 | todo |
| P1-2 | Barcode encoder and serial ranges | M | E-SERIAL-1 | P1-1 | todo |
| P1-3 | Pricing engine (MRP, markdown) | M | unit tests | P1-1 | todo |
| P1-4 | Permission matrix | S | E-AUTHZ-2 | P0-5 | todo |
| P1-5 | PDF hangtag builder | M | cell geometry tests | P1-2 | todo |

## P2 counter app
| ID | Task | Size | Acceptance | Depends on | Status |
|---|---|---|---|---|---|
| P2-1 | Drift tables, WAL, migrations | M | E-SERIAL-1 | P1 | todo |
| P2-2 | Lock screen, auth, idle lock | M | E-AUTH-1, 2 | P2-1 | todo |
| P2-3 | Stock entry (GRN matrix) and labels | L | stock tests | P2-1, P1-5 | todo |
| P2-4 | Billing register | L | E-SALE-1, E-OFFLINE-1 | P2-1 | todo |
| P2-5 | Returns and credit notes | M | E-RETURN-1 | P2-4 | todo |
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
