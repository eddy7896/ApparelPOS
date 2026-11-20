# Module: auth and roles
Status: Plan, nothing built (2026-11-17)

Purpose: lock screen, PINs, passwords, roles and idle lock.

- **Asked by owner:** cashier PIN of at least 6 digits with Argon2id; owner has full access.
- **Rules:** SSOT 1-4; ADR-0002, ADR-0003; guardrails 3, 5, 6.
- **Workflow:** the app opens on a lock screen; PIN opens Sales Mode, password opens Manager Mode; idle timeout locks; Ctrl+L locks manually.
- **Permission matrix (built in `core_domain`, P1-4; deny by default):**

| Permission | Cashier | Manager | Owner |
|---|---|---|---|
| sell, printBill, takeReturn, closeShift, viewStockAndPrices | yes | yes | yes |
| giveDiscount (cashier up to 10%, override needs manager's password) | yes, limited | yes | yes |
| overrideDiscountLimit | no | yes | yes |
| enterStock, printLabels, setMarkdown | no | yes | yes |
| viewCost, viewMargins, viewDaybook, viewReports | no | yes | yes |
| manageSettings, configureGst, manageUsers, backupAndRestore | no | yes | yes |

  Manager equals owner today by the owner's choice (2026-11-18). The cashier's discount limit as an owner-editable setting, the manager-password prompt and the lock screen are P2-2.
- **Built (P2-2, part 1, no screen yet):** PIN and password rules, lockout and idle-lock rules and Argon2id hashing in `core_domain`; the `users` table (schema v2), `AuthService` (create user, sign in with lockout saved per user, change PIN or password, deactivate, list names) in `apps/pos_windows/lib/data/`.
- **Not built:** the lock screen, idle timer and Ctrl+L (P2-2 part 2); the manager-password prompt for large cashier discounts (which account is checked and how its lockout works is undecided); first-owner setup at install (ADR-0002 D1); owner-editable lockout and idle settings.
- **Tasks:** P1-4, P2-2, P3-1.
- **Evals first:** E-AUTH-1, E-AUTH-2, E-AUTHZ-1, E-AUTHZ-2, E-ENC-1.
- **Not in scope:** cloud sign-in (release 2).
- **Open decisions:** none for the rules above (decided 2026-11-20); see Not built.
