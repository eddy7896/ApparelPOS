# Module: auth and roles
Status: Plan, nothing built (2026-11-17)

Purpose: lock screen, PINs, passwords, roles and idle lock.

- **Asked by owner:** cashier PIN of exactly 6 digits (was at least 6; owner, 2026-11-22) with Argon2id; owner has full access.
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
- **Built (P2-2 part 2):** the screens in `apps/pos_windows/lib/app/`: first-time owner setup, the lock screen (pick a name, PIN keypad for cashiers, hidden password for manager and owner, tries-left and lock messages), idle lock after 5 minutes, Ctrl+L and a Lock button, and an empty Sales Mode / Manager Mode shell. Every sign-in screen says the database is not encrypted yet. The app opens `apparel_pos.db` in its data folder on Windows (unverified on a real Windows machine) and an in-memory database in the browser preview. **No one has looked at these screens yet** (no screenshot could be taken here).
- **Built (P2-2, part 1):** PIN and password rules, lockout and idle-lock rules and Argon2id hashing in `core_domain`; the `users` table (schema v2), `AuthService` (create user, sign in with lockout saved per user, change PIN or password, deactivate, list names) in `apps/pos_windows/lib/data/`.
- **Not built:** the manager-password prompt for large cashier discounts (which account is checked and how its lockout works is undecided); adding cashiers (needs Manager Mode); owner-editable lockout and idle settings.
- **Encryption (P3-1, built 2026-11-21):** the database file is encrypted with SQLCipher; the key is made on first launch and kept in the Windows credential store (`apps/pos_windows/lib/data/encryption/`); the owner or manager is shown a recovery key once (`recovery_key_screen.dart`); see ADR-0003 points 7 to 11. Not done: restoring a backup with the recovery key (P3-2), changing the key, an owner setting for any of it.
- **Tasks:** P1-4, P2-2, P3-1.
- **Evals first:** E-AUTH-1, E-AUTH-2, E-AUTHZ-1, E-AUTHZ-2, E-ENC-1.
- **Not in scope:** cloud sign-in (release 2).
- **Open decisions:** none for the rules above (decided 2026-11-20); see Not built.

## Staff management in Manager Mode (built 2026-11-22)
Owner decisions, 2026-11-22: the owner and a manager add cashiers (name and a PIN of exactly 6 digits); only the owner adds managers or owners (password of at least 10 characters). A manager manages cashiers only; the owner manages everyone. Turning someone off keeps all their history (bills, returns, shifts are never edited) and they can be turned on again.
- Rules in `packages/core_domain/lib/src/staff_rules.dart`: who may manage whom, `cleanPersonName` (1 to 40 characters, no control characters), and `turnOffBlock`: nobody turns off themselves, the last active owner, or someone whose shift is still open.
- Data: `apps/pos_windows/lib/data/staff_repository.dart` (list, add, new PIN or password, rename, turn off and on; audit rows never hold a secret). A name is unique whatever its capitals, also against people who are turned off. A person may change their own PIN or password; a manager cannot reset another manager or the owner.
- Screen: `apps/pos_windows/lib/app/ui/staff_screen.dart`, "Staff" in the Manager Mode left menu. The sign-in names refresh after each change.
- **Counters are not added here.** Each counter is a separate laptop with its own database until sync (Release 2), so a second counter, its lot range and shared staff and stock wait for Release 2 (owner, 2026-11-22). ADR-0006 point 14 (who assigns a second counter's lot range) stays open.

## Operator IDs on the bill (built 2026-11-23)
Owner request, 2026-11-23: a customer's bill must not carry a staff member's name. Every person who signs in (cashier, manager or owner) has an **operator ID**, `OP001`, `OP002` and so on. The bill prints "Served by: OP001" in place of "Cashier: <name>". (Assumption: "the name of the stall" in the request meant the staff member's name; if the shop's own name should also stay off the bill, say so.)
- The number is given in order when the person is added (`users.staff_number`, schema v8, unique), is never reused, and stays with the person when they are turned off. People who existed before v8 get theirs in the order they were added.
- Rules in `packages/core_domain/lib/src/staff_code.dart` (`formatStaffCode`, `parseStaffCode`, `nextStaffNumber`, `billServedByLine`). The Staff screen shows each person's ID.
- The credit note slip never printed a staff name. Reports and the owner's lists inside the app still show names (they are not given to customers). Tests read the source to pin that the bill uses the ID.
