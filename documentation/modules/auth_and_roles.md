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
- **Tasks:** P1-4, P2-2, P3-1.
- **Evals first:** E-AUTH-1, E-AUTH-2, E-AUTHZ-1, E-AUTHZ-2, E-ENC-1.
- **Not in scope:** cloud sign-in (release 2).
- **Open decisions:** lockout delay length (default decided at build).
