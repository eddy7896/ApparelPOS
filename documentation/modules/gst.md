# Module: GST toggle
Status: Plan, nothing built (2026-11-17)

Purpose: the one-click path to GST invoices and reports when the shop registers. **All GST rules are unverified; the CA confirms them.**

- **Asked by owner:** a toggle; the owner enters GST details, chooses inclusive or exclusive billing, the rate (5% today, editable) and per-item or per-bill rounding.
- **Rules:** SSOT 12-14; ADR-0007.
- **Workflow:** release 1 stores tax fields on every sale item and keeps `gst_enabled` false. When enabled later, a setup screen collects the values and new bills use them; old bills are unchanged.
- **Tasks:** P3-4 (scaffold: settings, tax fields, field toggles). The catalogue below grows as the CA asks for more.
- **Evals first:** E-GST-1; a toggled-off field never prints, a toggled-on field always prints.
- **Not in scope:** e-invoicing, GST filing integrations.
- **Open decisions:** none. Which fields are legally mandatory is unverified; the CA confirms.

## Invoice field catalogue (owner toggles each; all unverified until the CA confirms)
Shop name; shop address; shop GSTIN; invoice number (unbroken series); invoice date and time; customer name; customer phone; customer GSTIN (for business buyers); item description; HSN code; quantity; unit price; discount; taxable value; GST rate; tax amount per item; CGST and SGST split; IGST; total tax; round-off; invoice total; amount in words; payment mode; cashier name; terms or return policy line; signature line.

## GST report catalogue (owner toggles each; all unverified until the CA confirms)
Sales summary by day and month; tax collected by rate; sales by HSN code; invoice register (list of invoices in a date range); returns and credit-note register; sales to business customers with GSTIN; purchases and input tax (needs purchase GST details, later); export to a spreadsheet file for the CA.
