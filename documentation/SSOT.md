# SSOT: product rules
Status: draft for Gate 3, 2026-11-17

Purpose: the single home of product behaviour. Tags: [ASSUMED] owner has not confirmed, [DESIGN] assistant proposal, [GUARD] guardrail, [ADR-nnnn] decided.

## Accounts and roles
1. Roles are CASHIER, MANAGER, OWNER. [ADR-0003]
2. Cashiers pick their name and sign in with a PIN of at least 6 digits; manager and owner use a password of at least 10 characters. Hashes use Argon2id. 5 wrong tries lock the account for 5 minutes (doubling to 1 hour); the screen locks after 5 idle minutes. [ADR-0002]
3. The owner and manager are the same person today. [owner]
4. A cashier discount above their limit (10% of the item price by default) needs the manager's password. [ADR-0003]

## Stock and barcodes
5. Every garment gets a unique serialized barcode: YYMM + 3-digit lot + 4-digit serial + 1 check digit (12 digits, Code 128 Subset C needs an even count; check digit approved by the owner 2026-11-18). [DESIGN, from owner spec]
6a. A purchase is entered in a Size x Color grid where every cell has its own quantity, cost and MRP (owner, 2026-11-20). The whole purchase is saved in one transaction. The counter keeps filling its current lot; a purchase that does not fit goes whole into the next lot and is never split (assistant's rule, unconfirmed). Counter 1 owns lots 000-499.
6. A barcode is unique across the shop. Each counter has its own reserved range of lot numbers (ranges never overlap), one lot at a time. [ADR-0008]
7. Statuses: IN_STOCK, SOLD, RETURNED, DAMAGED.

## Billing
8. A scanned barcode must be IN_STOCK; the same barcode cannot be added twice. [GUARD]
9. Price comes from the variant's MRP, then a markdown, which is either a percentage or a fixed amount (owner picks each time, decided 2026-11-18). A marked-down garment takes no cashier discount. Each garment keeps the MRP printed on its own tag (owner, 2026-11-20). Promos are out of release 1. [DESIGN]
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
