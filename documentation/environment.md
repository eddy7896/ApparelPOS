# Environment
Status: draft for Gate 3, 2026-11-17

Purpose: tool versions, how to run locally, and secrets handling. Only checked facts are stated.

## Verified in the current workspace (2026-11-17)
| Tool | Result |
|---|---|
| node | v22.23.4 |
| git | 2.43.0 |
| python3 | 3.13.18 |
| flutter | not installed (command not found) |
| dart | not installed (command not found) |

## Unverified (verify at setup, Phase 0)
Flutter and Dart versions; Windows build toolchain (Visual Studio C++ workload); Drift and SQLCipher compatibility on Windows; Argon2id package; Code 128 and PDF packages; Firebase CLI.

## Planned (does not exist yet)
- Run locally: `flutter run -d windows` in `apps/pos_windows` (planned).
- Checks: `node tools/checks/drift-check.mjs`, `dart test` (planned).

## Secrets
Names only in `.env.example` (planned). Real values: Firebase config and the database key live in the Windows credential store or the owner's password manager, never in the repository.

## Repository
https://github.com/eddy7896/ApparelPOS.git (not yet cloned in this workspace).
