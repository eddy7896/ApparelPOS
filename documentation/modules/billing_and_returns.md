# Module: billing and returns
Status: Bill rules built in `core_domain` (P2-4a, 2026-11-20); register, tables and screen not built

Purpose: scanning, pricing, payment and returns at the counter.

- **Asked by owner:** fast barcode billing, returns and credit notes, optional customer details.
- **Rules:** SSOT 8-11, 15-16; ADR-0007, ADR-0011.
- **Pricing (built in `core_domain`, P1-3):** price = MRP, then markdown (percent or fixed amount), then cashier discount; a marked-down garment takes no cashier discount; a percentage rounds half up. The cashier's discount limit and the manager override are P1-4.
- **Owner decisions (2026-11-20):** payments are cash, UPI, card, split, store credit note (needs P2-5) and pay later (udhaar, separate task P2-4d, questions first). Bill number is `2026-27/C1/000123` (financial year April to March by India time, counter, that counter's running number). A scanned barcode that is already sold or not in stock is blocked with a clear message, no manager override. The bill shows on screen with an A4/PDF print dialog; thermal printing waits for the printer model.
- **Bill rules built (P2-4a):** `BillNumber`, `financialYearLabel`, `Payment`, `PaymentMode`, `settle` (change comes only out of cash; UPI or card above the total is refused). Assistant's choices, unconfirmed: serial runs 1 to 999999 per counter and year; counter numbers 1 to 99; 'card' and 'upi' are recorded as the cashier's confirmation only.
- **Workflow:** scan, price, optional customer, choose payment, save; print or show the bill. Returns scan the hangtag, check SOLD status, refund the exact net price, restock or mark damaged.
- **Tasks:** P1-3, P2-4a to P2-4d, P2-5.
- **Evals first:** E-SALE-1, E-OFFLINE-1, E-RETURN-1, E-PRIV-1.
- **Not in scope:** promos, loyalty, card/UPI terminal integration, WhatsApp receipts, hold/resume (decide later).
- **Hardware (owner, 2026-11-17):** none yet. Receipts support both an ordinary A4 printer and a thermal receipt printer; a scanner is optional. Exact models are chosen later and then recorded here.
- **Open decisions:** printer and scanner models (owner will tell us).
