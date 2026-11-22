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
Flutter and Dart versions (on 2026-11-20 the Dart cache of the Homebrew Flutter 3.47.5 was missing `gen_kernel_aot.dart.snapshot`, so `dart compile kernel`, build_runner and sqlite3's build hook failed; the owner approved moving `bin/cache/dart-sdk` aside to `dart-sdk.bak` and re-downloading, which fixed it); Chrome for the development web preview (ADR-0016); Windows build toolchain (Visual Studio C++ workload); Inno Setup 6 on the CI runner (preinstalled or from Chocolatey: unverified which); the Visual C++ runtime DLLs copied from the runner's System32; SQLCipher loading and the Windows credential store on a real Windows machine (tests passed on macOS and the CI runner only); Argon2id package; Code 128 and PDF packages; Firebase CLI.

## Planned (does not exist yet)
- Run locally: `flutter run -d windows` in `apps/pos_windows` (planned).
- Checks: `node tools/checks/drift-check.mjs`, `dart test` (planned).

## Secrets
Names only in `.env.example` (planned). Real values: Firebase config and the database key live in the Windows credential store or the owner's password manager, never in the repository.

## Repository
https://github.com/eddy7896/ApparelPOS.git (not yet cloned in this workspace).
