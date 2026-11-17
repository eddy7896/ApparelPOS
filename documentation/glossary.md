# Glossary
Status: draft for Gate 3, 2026-11-17

Purpose: one definition per term.

| Term | Definition | Avoid |
|---|---|---|
| Article | One physical garment with its own barcode (serialized article) | item, SKU |
| Batch | One purchase receipt (GRN) with a code `YYMM` + 3-digit lot | lot (lot is the 3-digit part) |
| Blind close | Cash close where the cashier enters denominations and does not see the expected amount | |
| Counter | One billing station with its own local database and `counterId` | till, terminal |
| Lot | A 3-digit number in the barcode; each counter owns a range of lots so counters never issue the same barcode | batch (a purchase entry; one lot is used at a time) |
| Credit note | Barcode voucher issued on a return, with an expiry | store credit |
| Daybook | Ledger of all money movements | |
| GRN | Goods received note: entry of new stock | |
| Manager Mode | Counter app mode for the owner, with cost and reports | admin |
| MRP | Maximum retail price printed on the hangtag | |
| Paise | Integer money unit; 100 paise = 1 rupee | decimals |
| Basis points | Percentage as an integer; 100 basis points = 1% (5% is 500). Used so percentages never need a float | percent as decimal |
| Sales Mode | Counter app mode for the cashier, with no cost data | |
| Serial range | Block of barcode serials reserved for one counter | |
| Shift | Period a cashier works between opening and blind close | |
| Variant | A product in one size and color with its price | |
