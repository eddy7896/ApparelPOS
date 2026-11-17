# Project Brief: Apparel PoS
Status: confirmed by owner on 2026-11-17

## One-paragraph summary
A billing and stock system for a single apparel shop whose owner works on pen and paper today. It prints and scans barcodes, bills offline, handles returns and the daily cash close, and gives the owner daily analytics on a phone app. Source spec: project document `claude_code_tech_spec.md`. Repository: https://github.com/eddy7896/ApparelPOS.git

## Users and surfaces
| Kind of user | Signs in with | Device | Offline? | Surface (app) |
|---|---|---|---|---|
| Cashier (1 today) | PIN | Windows laptop | Yes | `pos_windows`, Sales Mode |
| Owner / manager (same person) | Password | Windows laptop, phone | Counter yes, phone no | `pos_windows` Manager Mode, `manager_mobile` |
| Future counters | PIN | Windows or Android tablet | Yes | Counter app (Android later) |

## Apps, services and packages (proposed list, to be tested at Gate 2)
| Name | Kind | One-line purpose | Used by |
|---|---|---|---|
| `pos_windows` | Flutter Windows app | Billing, stock, barcodes, returns, cash close | Cashier, owner |
| `manager_mobile` | Flutter Android/iOS app | Owner analytics and management (release 2) | Owner |
| `core_domain` | Dart package | Pricing, barcodes, shared rules | All apps |
| `sync_engine` | Dart package | Counter-to-cloud sync | Counter apps |

## Data and rules
- Main entities: products, batches, variants, serialized articles, sales, returns, shifts, daybook.
- Key business rules: a sold barcode cannot be sold again; a cash close is blind; returns link to the original sale.
- Walls: the cashier never sees cost prices, margins, procurement or daybook history.
- Audit requirement: every write records who and when.

## Sensitive data, jurisdictions, regulators (all legal points unverified)
- Customer phone and name optional at checkout; needs a privacy line (unverified, needs counsel).
- Shop is in India. Not GST registered today. All GST rules are unverified and need the owner's CA.

## Money
- Whole paise as integers, never floating point.
- GST off by default; tax breakdown stored from day one so one switch enables GST invoices and reports.

## Offline and reliability
- Each counter writes to its own local database first, then syncs to Firebase.
- Each counter gets its own reserved barcode range.
- Daily backup with a tested restore.

## Integrations (chosen / to choose)
- Firebase (Firestore) chosen for sync and the mobile app.

## Hosting, team and standards
- Firebase hosting; solo builder; English only; code on GitHub; private Project Hub, edit rights for the owner only.

## Quality bar
- Click targets of at least 48dp; a bill saves in under 1 second (owner, 2026-11-17).
- Hardware: the shop has no printer or barcode scanner yet. The app supports ordinary A4 printers and thermal receipt printers; models are chosen later by the owner.

## Out of scope for now
Loyalty, promos, card/UPI terminals, WhatsApp receipts, supplier payout ledger, multi-shop, Android counters, mobile app (release 2).

## Release 1
Billing, stock entry with barcodes, returns, daily cash close. Windows only, one counter.

## Biggest fears (first guardrails)
Lost sales data, a wrong cash count, a cashier seeing cost prices, downtime on a busy day.

## Decided by the assistant (owner may change)
| Decision | Why |
|---|---|
| Per-counter reserved barcode ranges | Two counters cannot issue duplicate barcodes |
| Same piece sold twice offline: earlier sale wins, the other is flagged (owner accepted 2026-11-17) | Rare in one shop |
| Windows only in release 1, shared code for Android later | Fits the budget |

## Open questions for the owner
| # | Question | Options | Needed by |
|---|---|---|---|
| 1 | None open | | |
