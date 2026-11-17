# System context: Apparel PoS
Status: draft for Gate 3, 2026-11-17

Purpose: what the product is, for whom, and the ideas that shape every decision.

## What it is
A billing and stock system for one apparel shop. Today the owner uses pen and paper. The system prints serialized barcode hangtags, bills at a counter with or without internet, handles returns, closes the day's cash, and shows the owner daily analytics on a phone.

## Actors
| Actor | What they do |
|---|---|
| Cashier | Bills customers, handles returns, closes a shift blind |
| Owner (also manager) | Enters stock, sets prices, prints labels, reads analytics, sets counters, backs up |
| Shop's CA (outside the system) | Advises on GST rounding and invoice layout before GST is enabled |

## The big ideas
1. **Offline-first.** The counter writes to its own local database first; the internet is only for sync.
2. **Every garment has its own barcode.** A sold barcode cannot be sold again.
3. **Cashier sees no cost data.** Enforced in queries and by database encryption, not only on screen.
4. **Integer paise.** No floating-point money. GST fields exist from day one, switched on later by the owner.
5. **One counter now, more later.** Each counter has its own database and barcode range.

## What it is not (release 1)
Loyalty, promos, card/UPI terminals, WhatsApp receipts, supplier payout ledger, multi-shop, Android counters, the manager mobile app.
