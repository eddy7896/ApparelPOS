# Module: cash close and daybook
Status: Shift rules built in `core_domain` (P2-6a, 2026-11-21); shifts, daybook and screens not built

Purpose: end-of-shift cash count and the money ledger.

- **Asked by owner:** an accurate daily cash close and daily analytics.
- **Rules:** SSOT 17, 20; guardrail 2; ADR-0006.
- **Workflow:** cashier enters denominations, the system stores expected and declared cash, locks the shift and reports the variance to the owner only.
- **Owner decisions (2026-11-21):** the cashier opens a shift with the cash in the drawer (counted by notes and coins) and ends it with a blind count; sales and returns need an open shift; expected cash is opening cash plus cash kept from sales minus cash refunds (UPI, card and credit note money is not in the drawer); any difference is shown to the owner, no tolerance; the count lists notes 500, 200, 100, 50, 20, 10 and coins 10, 5, 2, 1.
- **Rules built (P2-6a):** `Denomination` (a 10 rupee note and coin are separate), `countCash` (a count over 100,000 of one denomination is taken as a typing mistake: assistant's choice), `expectedCash`, `CashVariance` (counted minus expected; negative is short), `ShiftCloseReceipt` (what the cashier gets back: no expected amount, no variance).
- **Plan:** P2-6b tables (`shifts`, `shift_closes`, `daybook`, shift id on bills and returns; schema v6; a shift row and its close row are never edited), P2-6c screens (the owner's shift list is the only place a variance shows; the daybook and reports are P2-7). Assistant's choices, unconfirmed: one open shift per cashier; a manager or owner who sells or takes a return also needs their own open shift; the daybook is a table written in the same transaction as the sale or return, one row per payment mode (not derived later).
- **Tasks:** P2-6a to P2-6c, P2-7.
- **Evals first:** E-SHIFT-1, E-AUDIT-1.
- **Not in scope:** supplier payouts, expenses beyond petty cash (decide later).
- **Open decisions:** none.
