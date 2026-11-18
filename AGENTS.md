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
| `packages/core_domain`: `Money` (integer paise, half-up percent rounding) with 15 tests; `Barcode`, `LotRange`, `LotCursor` (12-digit barcodes, 35 tests in total) and `apps/pos_windows` skeleton (1 widget test) | |
| Check scripts in `tools/checks/`, `evals/`, `tools/hub/`; Project Hub in `documentation/hub/`; CI workflow (`.github/workflows/ci.yml`), PR template, CODEOWNERS | |
| Dart 3.13.4 and Flutter 3.47.5 on the macOS dev machine; CI job `dart-flutter-windows` analyzes, tests and builds `pos_windows` on Windows (passed on PR #6) | Running `pos_windows` on a real Windows machine (unverified: only a CI build so far) |

## Commands
- `npm run check:drift` runs `node tools/checks/drift-check.mjs` (documents vs files).
- `npm run check:project-rules` runs the money-float and Firestore-import rules.
- `npm run eval:hallucination` grades the golden set against `evals/ideal-answers.json`.
- `npm run test:checks` runs the tests of the check scripts.
- `npm run check:branch` checks a pull request's branch edge (CI sets the branch names).
- `dart pub get`, `dart analyze`, `dart test` in `packages/core_domain`; `flutter pub get`, `flutter analyze`, `flutter test` in `apps/pos_windows`. Each folder is set up on its own (no workspace).
- Planned (do not assume they exist): `flutter run -d windows`, `flutter build windows`.

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
