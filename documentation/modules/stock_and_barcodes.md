# Module: stock and barcodes
Status: Plan, nothing built (2026-11-17)

Purpose: entering stock and printing hangtags.

- **Asked by owner:** enter goods by size and color, print a barcode per garment, hangtag shows shop name, style, size, color, MRP.
- **Rules:** SSOT 5-7; ADR-0006, ADR-0008.
- **Workflow:** owner enters a purchase (supplier, cost, MRP) in a Size x Color grid, saves in one transaction, serials are issued from the counter's range, labels print as A4 sheets (starting at a chosen cell) or thermal rolls.
- **Data:** batches, batch variants, serialized articles.
- **Tasks:** P1-2, P1-5, P1-5b, P2-3.
- **Evals first:** E-SERIAL-1; label cell geometry; 50-article save is fast (spec target under 50 ms, unverified).
- **Not in scope:** CSV import (later), supplier ledger.
- **Barcode:** 12 digits (YYMM, lot, serial, Luhn check digit). Built in `core_domain` (`Barcode`, `LotRange`, `LotCursor`); label drawing is P1-5.
- **Hangtag (owner, 2026-11-18):** A4 sheet, 3 columns x 8 rows (70 x 37.125 mm), MRP as "₹499.00" with Indian digit grouping (₹1,00,000.00; grouping is the assistant's assumption). Built in `core_domain`: sheet geometry in whole micrometres, start-cell pagination, `formatRupees`, `LabelContent`, and a Code 128 Subset C encoder (P1-5). PDF drawing with an embedded font that has the ₹ sign is P1-5b.
- **Open decisions:** who assigns each counter's lot range and where it is stored (P2-1); Luhn as the check digit algorithm (owner to confirm).
