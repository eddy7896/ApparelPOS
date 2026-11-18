# SSOT: product rules
Status: draft for Gate 3, 2026-11-17

Purpose: the single home of product behaviour. Tags: [ASSUMED] owner has not confirmed, [DESIGN] assistant proposal, [GUARD] guardrail, [ADR-nnnn] decided.

## Accounts and roles
1. Roles are CASHIER, MANAGER, OWNER. [ADR-0003]
2. Cashiers sign in with a PIN of at least 6 digits; manager and owner use a password. Hashes use Argon2id. [ADR-0002]
3. The owner and manager are the same person today. [owner]
4. A cashier discount above their limit needs the manager's password. [DESIGN]

## Stock and barcodes
5. Every garment gets a unique serialized barcode: YYMM + 3-digit lot + 4-digit serial + 1 check digit (12 digits, Code 128 Subset C needs an even count; check digit approved by the owner 2026-11-18). [DESIGN, from owner spec]
6. A barcode is unique across the shop. Each counter has its own reserved range of lot numbers (ranges never overlap), one lot at a time. [ADR-0008]
7. Statuses: IN_STOCK, SOLD, RETURNED, DAMAGED.

## Billing
8. A scanned barcode must be IN_STOCK; the same barcode cannot be added twice. [GUARD]
9. Price comes from the variant's MRP, then a markdown, which is either a percentage or a fixed amount (owner picks each time, decided 2026-11-18). A marked-down garment takes no cashier discount. Promos are out of release 1. [DESIGN]
10. Customer name and phone are optional at checkout. [ADR-0011]
11. Payment types: cash, UPI (QR and manual reference), card (manual reference).

## Money and GST
12. All money is integer paise. [ADR-0007]
13. GST is off by default; the owner enables it, then picks inclusive or exclusive billing, the rate and the rounding level. [ADR-0007]
14. GST rules are unverified until the CA confirms. [ADR-0007]

## Returns
15. A return requires a SOLD barcode and refunds the exact net price paid, including the tax charged. [DESIGN]
16. Refund modes: cash, UPI, credit note, exchange. A credit note is a barcode with an expiry date.

## Cash close
17. Shift close is blind: the cashier enters denominations only and does not see the expected amount. The variance goes to the owner. [DESIGN, from owner spec]

## Offline and sync
18. Billing never needs the internet. [ADR-0008]
19. A same-barcode double sale across counters keeps the earlier sale and flags the other. [ADR-0008]

## Backups
20. A daily backup goes to a USB drive and a folder; a restore is tested. [ADR-0015]
