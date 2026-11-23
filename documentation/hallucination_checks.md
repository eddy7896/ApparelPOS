# Hallucination checks
Status: draft for Gate 3, 2026-11-17

Purpose: the ground truth an AI agent is graded against. Golden set and grader are created in Phase 3 (`evals/hallucination-golden.json`).

## 1. Architectural truths
| Question | Answer | Source |
|---|---|---|
| Does billing need the internet? | No; the counter writes locally first | ADR-0008 |
| Can an app talk to Firestore directly? | No; only `sync_engine` | ADR-0004 |
| Does anything exist yet in the repository? | No code exists; everything is Planned | `AGENTS.md` |
| Is the cashier's cost-price hiding only a UI feature? | No; queries omit cost columns and the database is encrypted | ADR-0003 |
| How are PINs hashed? | Argon2id, exactly 6 digits (min and max are both 6, owner 2026-11-22) | ADR-0002 |
| Is there a backend server? | No; Firebase only | ADR-0004 |
| Is GST on by default? | No | ADR-0007 |

## 2. Technology constraints and banned list
Stack: Flutter/Dart, Drift (SQLite, WAL), SQLCipher, Cloud Firestore, Firebase Auth (ADR-0004).
Banned: custom backend server, floating-point money, per-scan real-time streaming, SHA-256 for PINs, UI-only access control.

## 3. Fact-checking guidelines
Before implementing, verify: does it work offline; does the cashier path avoid cost columns; is money an integer; is the dependency version in the lockfile; does the package support Windows.

## 4. Domain truths
- Roles: CASHIER, MANAGER, OWNER.
- Barcode: 12 digits, YYMM + 3-digit lot + 4-digit serial + 1 check digit (originally 11; check digit approved 2026-11-18).
- Money: paise. Time: UTC stored, Asia/Kolkata for "today".
- Language: English only.

## 5. Verified environment truths
- 2026-11-17: `flutter` and `dart` are not installed in the current workspace (command not found). Versions are **unverified**.
- 2026-11-17: `node` v22.23.4, `git` 2.43.0, `python3` 3.13.18 are present.

## 6. Things that must be answered "unverified" or "does not exist yet"
GST rate legality, GST invoice layout, Firebase pricing, Drift with SQLCipher on Windows, any package version, any release 2 behaviour.

## 7. Automated enforcement
`npm run check:drift`, `npm run check:project-rules` and `npm run eval:hallucination` (golden set: `evals/hallucination-golden.json`, 40 items).

When an agent is caught hallucinating, add a golden item and, if mechanical, a drift rule.
