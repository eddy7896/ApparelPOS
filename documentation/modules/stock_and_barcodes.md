# Module: stock and barcodes
Status: Plan, nothing built (2026-11-17)

Purpose: entering stock and printing hangtags.

- **Asked by owner:** enter goods by size and color, print a barcode per garment, hangtag shows shop name, style, size, color, MRP.
- **Rules:** SSOT 5-7; ADR-0006, ADR-0008.
- **Workflow:** owner enters a purchase (supplier, cost, MRP) in a Size x Color grid, saves in one transaction, serials are issued from the counter's range, labels print as A4 sheets (starting at a chosen cell) or thermal rolls.
- **Data:** batches, batch variants, serialized articles.
- **Tasks:** P1-2, P1-5, P1-5b, P2-3a, P2-3b.
- **Evals first:** E-SERIAL-1; label cell geometry; 50-article save is fast (spec target under 50 ms, unverified).
- **Not in scope:** CSV import (later), supplier ledger.
- **Barcode:** 12 digits (YYMM, lot, serial, Luhn check digit). Built in `core_domain` (`Barcode`, `LotRange`, `LotCursor`); label drawing is P1-5.
- **Hangtag (owner, 2026-11-18):** A4 sheet, 3 columns x 8 rows (70 x 37.125 mm), MRP as "₹499.00" with Indian digit grouping (₹1,00,000.00; grouping is the assistant's assumption). Built in `core_domain`: sheet geometry in whole micrometres, start-cell pagination, `formatRupees`, `LabelContent`, and a Code 128 Subset C encoder (P1-5). PDF drawing (P1-5b, built): `layoutHangtag` places bars and text in each cell, `buildHangtagPdf` writes the sheet with Noto Sans (ADR-0017). Not yet printed or scanned on real hardware; text sizes are the assistant's defaults; thermal rolls are not built.
- **Database (P2-1, built):** Drift/SQLite tables `counters`, `products`, `variants`, `batches`, `batch_lines` (costs only here), `articles` (barcode unique, own MRP, status), `audit_log`, `outbox`; WAL; schema version 1 dumped to `apps/pos_windows/drift_schemas/`. Not encrypted yet (P3-1). The save-a-purchase workflow is P2-3.
- **Purchase entry (P2-3a, built, no screen yet):** `core_domain` `checkPurchase` and `planPurchase`; the app's `StockRepository` saves a purchase in one transaction (permission `enterStock`), keeps the size and color lists (starting with S, M, L, XL, XXL and nine common colors) and the shop name, and rebuilds a batch's labels (`printLabels`, needs the shop name). Measured: 50 garments saved in 36 ms on this Mac with an in-memory database (target 50 ms; not measured on Windows or a file database). P2-3b is the screen and printing.
- **Open decisions:** who assigns each counter's lot range and where it is stored (P2-1); Luhn as the check digit algorithm (owner to confirm).
