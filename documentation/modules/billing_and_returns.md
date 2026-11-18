# Module: billing and returns
Status: Plan, nothing built (2026-11-17)

Purpose: scanning, pricing, payment and returns at the counter.

- **Asked by owner:** fast barcode billing, returns and credit notes, optional customer details.
- **Rules:** SSOT 8-11, 15-16; ADR-0007, ADR-0011.
- **Pricing (built in `core_domain`, P1-3):** price = MRP, then markdown (percent or fixed amount), then cashier discount; a marked-down garment takes no cashier discount; a percentage rounds half up. The cashier's discount limit and the manager override are P1-4.
- **Workflow:** scan, price, optional customer, choose payment, save; print or show the bill. Returns scan the hangtag, check SOLD status, refund the exact net price, restock or mark damaged.
- **Tasks:** P1-3, P2-4, P2-5.
- **Evals first:** E-SALE-1, E-OFFLINE-1, E-RETURN-1, E-PRIV-1.
- **Not in scope:** promos, loyalty, card/UPI terminal integration, WhatsApp receipts, hold/resume (decide later).
- **Hardware (owner, 2026-11-17):** none yet. Receipts support both an ordinary A4 printer and a thermal receipt printer; a scanner is optional. Exact models are chosen later and then recorded here.
- **Open decisions:** printer and scanner models (owner will tell us).
