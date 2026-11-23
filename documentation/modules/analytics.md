# Module: analytics
Status: built 2026-11-22 (Release 1 counter app, Manager Mode). Mock-up board 8 in the redesign mock-up.

Purpose: let the manager and owner see how the shop is doing without a spreadsheet: sales over time, busy hours, how customers pay, best sellers, what is not selling, and cash over and short.

## What it shows (all from the shop's own database, no internet)
- A date filter: last 7 days or last 30 days, compared with the same number of days just before.
- Headline numbers: net sales and the change against the period before, bills and average bill, returns rate, and profit (manager and owner only).
- Sales each day: a line with the period before dashed behind it; tap or hover a day for the numbers; "Show as a table" gives the same numbers.
- What the days say: rising, falling or steady; the best day; the strongest and quietest weekday; the busiest hour; the slow movers.
- Busiest hours (bills per hour, India time), how customers paid (from the daybook), best sellers by garments or sales, how much of each style has sold, and cash over and short for the last 8 shift closes.

## Rules (in `packages/core_domain/lib/src/analytics_rules.dart`)
Definitions below are the assistant's, **to be confirmed by the owner**:
- A **slow mover** is a style whose first purchase is at least **30 days** old, with **less than 25%** of what was bought sold, and some still unsold. Sold means the garment's status is SOLD (a damaged or restocked return is not counted as sold).
- The trend is **rising** or **falling** when the later half of the days sells at least **5%** more or less than the earlier half (the middle day of an odd count belongs to neither half); otherwise **steady**. With nothing sold in the earlier half there is no comparison, so it is steady.
- The change against the period before is whole basis points rounded toward zero; with nothing sold before, no percentage is shown.
- Net sales, profit and the day boundaries use the same definitions as the daily report (ADR-0007: India calendar day; net sales = sales minus refunds; profit = net sales minus cost of goods).

## Who may see it
`viewReports` (manager, owner). Profit needs `viewMargins` as well and is the only part that reads cost (E-AUTHZ-1); a test pins that the cost table appears only in the profit query. Cashiers have no way to the screen and the repository refuses them.

## Where it is
`apps/pos_windows/lib/data/analytics_repository.dart`, `apps/pos_windows/lib/app/ui/analytics_screen.dart` (charts drawn without a package; colors in `chart_colors.dart`), reached from "Analytics" in the Manager Mode left menu.

## Not built
The "Last 7 days" card on the Manager home page (the mock-up shows one); a dark theme; charts for the owner's mobile app and web dashboard (Release 2, which will read the synced data); alerts when a style goes slow.
