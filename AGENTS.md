# AGENTS.md: Apparel PoS

Billing and stock system for one apparel shop: a Flutter Windows counter app (release 1) with an offline encrypted SQLite database, plus a sync package and an owner mobile app (release 2). Business rules live only in `core_domain`. Repository: https://github.com/eddy7896/ApparelPOS.git

## Read order (highest wins)
1. `documentation/decisions/` (accepted ADRs)
2. `documentation/guardrails.md`, `documentation/hallucination_checks.md`
3. `documentation/system_architecture.md`, `documentation/SSOT.md`
4. `documentation/project_brief.md`, `documentation/modules/README.md`
5. `documentation/implementation_plan.md`
6. Code. If code and documents disagree, stop and flag it.

Also: `documentation/system_context.md`, `eval_plan.md`, `agent_contexts.md`, `glossary.md`, `environment.md`, `live_documents.md`, `system_memory.md`.

## Current reality
| Exists | Planned (do not assume it exists) |
|---|---|
| Documents and ADRs in `documentation/` | `firebase/`, `packages/sync_engine`, `apps/manager_mobile`, all business rules |
| `packages/core_domain`: `Money` (integer paise, half-up percent rounding) with 15 tests; `Barcode`, `LotRange`, `LotCursor` (12-digit barcodes), `priceLine` and `PriceCut` (MRP, markdown, cashier discount; `Role`/`Permission` matrix with discount limit; hangtag sheet geometry, `formatRupees`, Code 128C encoder, hangtag artwork and PDF writer (`package:core_domain/hangtag_pdf.dart`, Noto Sans font in `assets/fonts/`, ADR-0017); 513 tests in total; bill number and payment rules (P2-4a), `SalesRepository` (cashier-safe lookup, save a bill; schema v4 with bills tables and no-edit triggers), billing register screen and A4 bill PDF (P2-4c), `parsePriceCut`, return rules and credit notes (P2-5a), `ReturnsRepository` and credit note use on a bill (P2-5b; schema v5, `approveLateReturn` permission), returns screen, credit note slip, credit notes and exchange at the register (P2-5c), shift rules (P2-6a), `ShiftRepository`, daybook, shifts needed for sales and returns, open-shift screen (P2-6b; schema v6), blind close screen, forced close of an earlier day's shift, owner's list of closes (P2-6c), report rules (P2-7a: India day, net sales, cost of goods, profit, top styles), `ReportRepository` daily report (P2-7b), daily report screen (P2-7c), SQLCipher encryption with the key in the Windows credential store and a recovery key shown once (P3-1: `lib/data/encryption/`, `RecoveryKey` in core_domain), backup rules (P3-2a: file names, keep 60, when due), backup service and restore (P3-2b: `lib/data/backup/`), backup screens, restore screen, first-launch restore and automatic backups (P3-2c; `file_selector`), Windows installer script `installer/apparel_pos.iss` (Inno Setup, per-user, unsigned) built and smoke-tested in CI, and `npm run check:data-location` pinning the data folder names (P3-3a), branding as data (UX-1: shop name, main color and logo are settings with placeholder defaults, rules in core_domain, `BrandRepository`, theme and marks that follow them; no shop-facing settings screen until the Release 2 mobile app), register popup for bill done, quick cash, 48 dp targets (UX-2), shift opens at sign-in in a popup, Pause (break) with `shift_breaks` (schema v7), top bar Pause, Close shift, Lock (UX-3), Manager Mode home with a left rail and a Today page (UX-4), returns popup and big refund panel (UX-5; stock entry not restyled), stock lookup for cashiers and managers (`StockLookupRepository`, `stock_lookup_screen.dart`; style, size, color, MRP, count in stock, never cost), demo stock added with the practice users in development builds only (`apps/pos_windows/lib/data/demo_stock.dart`), analytics for manager and owner with charts, trend reading and slow movers (`documentation/modules/analytics.md`), staff management in Manager Mode: add cashiers (owner also managers), new PIN, rename, turn off and on (`documentation/modules/auth_and_roles.md`; counters wait for Release 2), screens aligned to the redesign mock-up (neutral tokens in `ui_tokens.dart`, theme, sign-in with name tiles, dots and a big keypad, amber break screen with a running clock, drawer count with plus and minus, two-column blind close, register cards, F2 and F9, shift pill in the top bar), billing search by item name (pick a size and color, lowest in-stock barcode goes on the bill) and several of one size and color at once (quantity box and a +1 on each bill line; `pickGarments` in core_domain), `CHANGELOG.md`, `documentation/feature_log.md`, `documentation/release_process.md` and the tag-triggered release workflow `.github/workflows/release.yml` that attaches the installer to a GitHub Release (P3-3c; no release has been made yet), sign-in rules, Argon2id `CredentialHasher` at `package:core_domain/credential_hasher.dart`); `apps/pos_windows/lib/data/app_database.dart`: Drift stock tables, WAL, `AuditedWriter`, `AuthService` and `users` table; sign-in screens (first-time owner setup, lock screen, idle lock, Ctrl+L) and an empty Sales/Manager shell in `apps/pos_windows/lib/app/`; browser preview opens an in-memory database with the third-party binary `apps/pos_windows/web/sqlite3.wasm` (ADR-0016); `StockRepository` (purchase save, size and color lists, shop name, labels for a batch); stock entry screen with print preview (`apps/pos_windows/lib/app/ui/stock_entry_screen.dart`, `printing` 5.15.1); `parseRupees` in core_domain; 690 app tests (schema v7, migration tested, encrypted with SQLCipher; Windows runtime unverified) and `apps/pos_windows` skeleton (1 widget test; Windows and web targets, web is a development preview only, ADR-0016) | |
| Check scripts in `tools/checks/`, `evals/`, `tools/hub/`; Project Hub in `documentation/hub/`; CI workflow (`.github/workflows/ci.yml`), PR template, CODEOWNERS | |
| Dart 3.13.4 and Flutter 3.47.5 on the macOS dev machine; CI job `dart-flutter-windows` analyzes, tests and builds `pos_windows` on Windows (passed on PR #6) | Running `pos_windows` on a real Windows machine (unverified: only a CI build so far) |

## Commands
- `npm run check:drift` runs `node tools/checks/drift-check.mjs` (documents vs files).
- `npm run check:project-rules` runs the money-float and Firestore-import rules.
- `npm run check:data-location` checks the Windows identity (CompanyName, ProductName, window title, installer AppId) is unchanged: it decides where the shop's data lives.
- `npm run check:changelog` checks `CHANGELOG.md` has a dated entry for the app's version (`apps/pos_windows/pubspec.yaml`).
- `npm run eval:hallucination` grades the golden set against `evals/ideal-answers.json`.
- `npm run test:checks` runs the tests of the check scripts.
- `npm run check:branch` checks a pull request's branch edge (CI sets the branch names).
- `dart run build_runner build` in `apps/pos_windows` regenerates `apps/pos_windows/lib/data/app_database.g.dart` (CI fails if it is stale); `dart run drift_dev schema dump lib/data/app_database.dart drift_schemas/` records a schema version.
- `dart pub get`, `dart analyze`, `dart test` in `packages/core_domain`; `flutter pub get`, `flutter analyze`, `flutter test` in `apps/pos_windows`. Each folder is set up on its own (no workspace).
- Browser preview for development (ADR-0016): `flutter run -d chrome` in `apps/pos_windows`; `flutter build web` is also in CI. It does not verify encryption, printing, scanning or backups. Opened in headless Chrome on 2026-11-21 (sign-up screen draws); a build that compiles is not proof it runs, so open it after changing start-up code.
- Planned (do not assume they exist): `flutter run -d windows`.

## Non-negotiable rules
1. Billing never needs the internet. Review only until E-OFFLINE-1 exists.
2. Money is integer paise; no `double` in money code. (E-MONEY-1)
3. Cashier code never selects cost columns; the database is encrypted. (E-AUTHZ-1, E-ENC-1)
4. PINs have at least 6 digits and are hashed with Argon2id. (E-AUTH-1)
5. A barcode is unique; each counter issues from its own range. (E-SERIAL-1)
6. A sold barcode cannot be sold twice. (E-SALE-1)
7. Only `sync_engine` imports Firestore. (drift rule)
8. Sales, returns and daybook rows are never edited; reverse them. (E-AUDIT-1)
9. No secrets in the repository. (secret scan)
10. GST is off by default; rules are unverified until the CA confirms. (E-GST-1)
11. Never weaken a check to make it pass.

## Branching
`main` (releases) <- `develop` <- `feat|fix|chore/<topic>`; `hotfix/<name>` to `main` then back-merge. No direct pushes; the owner merges. (ADR-0013, Proposed)

## Anti-hallucination protocol
Verify a file, API, version or flag before citing it; otherwise write "unverified". Do not invent paths. Library versions come from the lockfile. State commands run and results. Flag disagreements; do not choose silently. Law, prices and vendor limits need a source and date, or "unverified". Do not fill requirement gaps; ask.

## Definition of done
Drift check clean; evals written first and passing; permission tests for new operations; documents updated (status, ADR, glossary, "Current reality"); summary lists what was run and not verified; pull request opened with the template; Project Hub refreshed.

## Cadence
Every pull request: unit, database, drift, branch policy. Monthly and after document changes: golden set. At each gate: everything. Before go-live: restore test.

## Working preferences
See `documentation/working_preferences.json` (auto, checkpoints, minimal).
