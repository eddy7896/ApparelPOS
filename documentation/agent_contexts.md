# Agent contexts
Status: draft for Gate 3, 2026-11-17

Purpose: personas per area, with the folders each may touch and one strict rule. Folders are planned.

## Domain engineer
- **Folders:** `packages/core_domain/`
- **Goal:** correct, pure, tested rules for money, pricing, barcodes and permissions.
- **Key concepts:** integer paise, serial ranges, permission matrix.
- **Strict rule:** no Flutter, database or network imports in this package.

## Windows app engineer
- **Folders:** `apps/pos_windows/`
- **Goal:** fast, offline billing and stock screens.
- **Strict rule:** never select cost columns in Sales Mode; never call business rules that belong to `core_domain`.

## Database engineer
- **Folders:** `apps/pos_windows/lib/db/`
- **Goal:** Drift tables, migrations, encryption, backups.
- **Strict rule:** every change that adds a table or column has a migration and a test; audit and outbox rows are written in the same transaction.

## Sync engineer (release 2)
- **Folders:** `packages/sync_engine/`, `firebase/`
- **Strict rule:** only this package imports Firestore; rules deny by default.

## Mobile engineer (release 2)
- **Folders:** `apps/manager_mobile/`
- **Strict rule:** reads summaries and writes commands only; no direct database access.

## DevOps
- **Folders:** `.github/`, `tools/`
- **Strict rule:** never weaken a check to make it pass.

## Design rules (all UI)
Colors `#FFFFFF`, `#09090B`, `#E2E8F0`; accent configurable; fonts Space Grotesk, Inter, JetBrains Mono; click targets of 48dp or more and a bill saved in under 1 second (owner, 2026-11-17).
