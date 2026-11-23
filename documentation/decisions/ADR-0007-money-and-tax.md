# ADR-0007: Money, GST toggle and time

- **Status:** Accepted (2026-11-17, owner)
- **Origin:** Decided by the owner (integers; GST toggle); rest proposed by the assistant

## Context
The shop is not GST registered. The owner wants GST invoices and reports switchable later. **All GST rules are unverified and need the owner's CA.**

## Decision
1. All money is an integer in paise; no floating point.
2. Each product stores `gst_pct` and each sale item stores the tax breakdown from day one, even while GST is off.
3. A single store setting `gst_enabled` (default false) turns on GST invoices and GST reports; switching it on never rewrites past bills.
4. When the owner enables GST, a setup screen asks for the GSTIN and shop details and for the billing mode: tax-inclusive or tax-exclusive. The owner chooses; nothing is hard-coded (decided by the owner, 2026-11-17).
5. GST rates are owner-editable settings, not constants in code. The owner states the current rate is 5% (unverified; the owner or CA confirms) and may change it later. A rate change applies only to new bills; past bills keep the rate they were issued with.
6. At GST setup the owner also chooses the rounding level: per item or per bill. It is a store setting applied by one function in `core_domain`, and the owner takes the CA's advice on which to pick (decided by the owner, 2026-11-17). Until GST is enabled, the default is per item.
7. The owner can change the rounding choice later; it applies to new bills only.
8. The GST invoice and reports are built from a catalogue of optional fields kept in `documentation/modules/gst.md`. When GST is enabled, the owner switches on the fields and reports their CA requires; nothing is hard-coded (decided by the owner, 2026-11-17). Which fields the law makes mandatory is **unverified**; the CA confirms, and the owner takes their advice when choosing.
9. Fractions of a paisa round half up (decided by the owner, 2026-11-18). For negative amounts (returns) the rule is applied to the absolute value and the sign restored, so a return reverses a sale exactly; this symmetric reading is the assistant's, please confirm. Percentages are integer basis points; `Money.percentBp` in `core_domain` is the only rounding function so far. Rounding level (per item or per bill, point 6) is not built yet.
10. Times are stored in UTC; "today" and shift boundaries use the shop's time zone (Asia/Kolkata).

## Alternatives considered
- **Add GST fields later:** forces a data migration; rejected.

## Consequences
- GST reports and invoice fields are built later but need no migration.

## Enforcement
| Rule | Check |
|---|---|
| No floating-point money | `npm run check:project-rules` and `packages/core_domain/test/money_test.dart` |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D3 | Inclusive/exclusive and rate | **Resolved 2026-11-17 (owner): chosen by the owner at GST setup; rate is an editable setting** | n/a |
| D3b | Rounding level | **Resolved 2026-11-17 (owner): chosen by the owner at GST setup (per item or per bill)** | n/a |
| D3c | GST invoice fields and reports | **Resolved 2026-11-17 (owner): an open catalogue; the owner toggles the fields and reports the CA requires when enabling GST** | n/a |
