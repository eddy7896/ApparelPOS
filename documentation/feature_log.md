# Feature log
Status: current to 2026-11-22 (release 0.9.0)

Purpose: every feature, task by task, with the pull request that built it, so the owner can see what exists and when it arrived. The release notes are in [CHANGELOG.md](../CHANGELOG.md); the plan is [implementation_plan.md](implementation_plan.md).

Pull request `#12` is https://github.com/eddy7896/ApparelPOS/pull/12. All are merged unless the "PR" column says open.

| Task | What it gives the shop | PR | Merged |
|---|---|---|---|
| P0-4 | Project documents, decisions, checks and the workflow | #1, #2 | 2026-11-17 |
| P0-5 | Empty counter app and rules package that build | #3 | 2026-11-17 |
| P1-1 | Money in whole paise (no rounding mistakes), half-up percent | #4 | 2026-11-17 |
| P1-2 | 12-digit barcodes with a check digit and per-counter lot ranges | #5 | 2026-11-17 |
| CI | Windows build and test job on GitHub | #6 | 2026-11-18 |
| P1-3 | Pricing: MRP, markdown, cashier discount | #7 | 2026-11-18 |
| P1-4 | Who may do what (cashier, manager, owner) | #8 | 2026-11-20 |
| P1-5 | A4 hangtag sheet layout, rupee text, Code 128 barcode | #9 | 2026-11-20 |
| Preview | Browser preview for development on any machine | #10 | 2026-11-20 |
| P1-5b | Hangtag PDF drawing with the rupee sign | #11 | 2026-11-20 |
| P2-1 | The local database and its tables | #12 | 2026-11-20 |
| P2-2 | Sign-in: owner set-up, PIN and password rules, Argon2id, lock screen, idle lock | #13, #14 | 2026-11-20 |
| P2-3 | Stock entry in a Size by Color grid, saving a purchase, printing hangtags | #15, #16 | 2026-11-20 |
| P2-4a | Bill numbers and payment rules | #17 | 2026-11-20 |
| P2-4b | Saving a bill in one step, cashier-safe lookup (no costs) | #18 | 2026-11-21 |
| P2-4c | The billing register screen and the printed bill | #19 | 2026-11-21 |
| P2-5a | Return and credit note rules | #20 | 2026-11-21 |
| P2-5b | Saving returns and credit notes, paying a bill with a note | #21 | 2026-11-21 |
| P2-5c | Returns screen, credit note slip, credit notes and exchange at the register | #22 | 2026-11-21 |
| P2-6a | Cash count rules (notes and coins, expected cash, variance) | #23 | 2026-11-21 |
| P2-6b | Shifts, the daybook, sales and returns need an open shift | #24 | 2026-11-21 |
| P2-6c | Blind close screen, forced close of an old shift, owner's list of closes | #25 | 2026-11-21 |
| P2-7a | Daily report rules (India day, profit, top styles) | #26 | 2026-11-21 |
| P2-7b | Daily report figures, checked against the daybook | #27 | 2026-11-21 |
| P2-7c | The owner's daily report screen | #28 | 2026-11-21 |
| P3-1 | Encrypted database, key in the Windows credential store, recovery key | #29 | 2026-11-21 |
| P3-2a | Backup rules (names, keep 60, when due) | #30 | 2026-11-21 |
| P3-2b | Backup service and restore to a clean machine | #31 | 2026-11-21 |
| P3-2c | Backup and restore screens, first-launch restore, automatic backups | #32 | 2026-11-21 |
| P3-3a | Windows installer, pinned data location, install test in CI | #33 | 2026-11-22 (check the PR) |
| P3-3c | Release process: changelog, feature log, release workflow with the installer attached | open (see the pull request list) | |

## Planned, not built
| Task | What | Waiting for |
|---|---|---|
| P3-3b | Runbook for the owner (install, first day, laptop fails, database corrupt, restore, go-live checklist) | owner's go-ahead |
| P3-4 | GST setup (off by default; rules unverified until the CA confirms) | the CA |
| P2-4d | Pay later (udhaar): customers, balance owed, later payments | owner's questions answered |
| P2-4e | Markdown at the register | owner's go-ahead |
| P4 | Sync, cloud, the owner's phone app, a second counter (Release 2) | after go-live |
