# Changelog

All notable changes to Apparel PoS. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the versions follow [Semantic Versioning](https://semver.org/). Every item names the pull request that made it (`#12` is https://github.com/eddy7896/ApparelPOS/pull/12). The full task by task list is in [documentation/feature_log.md](documentation/feature_log.md). How a release is made is in [documentation/release_process.md](documentation/release_process.md).

## [Unreleased]

Nothing yet. Planned next: GST reports that need new data (HSN codes, customer GSTIN, purchases) and Release 2 (sync, cloud, owner mobile app).

## [0.9.0] - 2026-11-23

The first release: a release candidate of **Release 1, the Windows counter app** for one apparel shop. It is a **pre-release**: it has been built and tested by the automatic checks, but it has **not yet been run on a real shop laptop** (see Known limitations).

### Added

**Redesign and extras added since the first candidate** (#35 to #61)
- A new look that follows one shop color and a neutral set of colors: sign-in with name tiles and a big keypad, a left menu and a Today page in Manager Mode, a register with a popup for "bill done", quick cash buttons and 48 dp touch targets, a shift popup at sign-in, Pause for a break with a running clock, and a returns popup with a big refund panel (#36 to #40, #46, #50).
- The shop's name, main color and logo are data, not code (the screens to set them wait for the owner's phone app) (#36).
- Stock lookup for cashiers and managers: style, size, color, MRP and count; out of stock in red, running low (2 or fewer) in amber, with a summary and filters (#41, #48). Development builds add demo stock with the practice users (#42).
- Analytics for manager and owner: 7 and 30 days, busy hours, sales by category, trend reading and slow movers (#43). The daily report gets headline tiles, charts and a table view (#47).
- Staff management: add cashiers (the owner also managers), new PIN or password, rename, turn off and on (#44). A cashier PIN is exactly 6 digits (#49). The bill says "Served by OP001" with an operator ID, never a staff name (#51).
- Billing: search by item name as well as by tag, and several of one size and color at once (#45); a payment card with Cash, UPI, Card and Split (#50).
- Stock categories in two levels, set up in Settings, used in lookup, search, analytics and the daily report (#52).

**Money and the shop, added since the first candidate**
- GST reports (Manager Mode, GST reports): invoice register, returns register, tax by rate and by day for a range of days, and an export of three CSV files for the CA. Unverified until the CA says which reports they need.
- The owner's runbook (`documentation/owner_runbook.md`): install, the first start and the recovery key, a normal day, stock and hangtags, what to do when something goes wrong, a new laptop, and a go-live checklist. Written from what the app does; not yet tried on a real laptop.
- GST, switched off: the owner (only) can switch GST on in Settings (GSTIN, address, rate, tax included or added, rounding, which fields to print). New bills then work out and keep the tax per garment, the total adds it when tax is added on top, the bill prints as a TAX INVOICE with the fields the owner chose, returns refund the tax too, and the daily report shows GST and leaves it out of profit. Every GST rule is unverified until your CA confirms it. GST reports are not built yet. Database version 12.
- Pay later (udhaar): a manager or the owner may let a bill be left unpaid (customer name and phone required; a cashier asks a manager to type their password); customers pay later in cash, UPI or card, the oldest bill first (a Pay later page in Manager Mode and a Pay dues button at the register); a return from an unpaid bill first takes down what is owed; only the owner writes a debt off. The register, the bill, the returns screen, the blind close and the daily report all follow it. Database version 11.
- Markdowns: a manager or the owner sets a percentage or an amount off a whole style until a last day (Manager Mode, Markdowns). The register applies it by itself and a marked-down garment takes no cashier discount. Database version 10.
- Daily report: each closed shift shows its break time.
- Register: F4 puts a bill aside (Hold bill) so another customer can be served, with Resume or drop for each held bill; F6 starts a fresh search; Esc closes the bill-done popup or the name list. A held bill is kept only in memory.

- The app's text uses the Inter font, bundled so every laptop looks the same; the bill and hangtag PDFs use Noto Sans.

**Stock and hangtags**
- Enter a purchase in a Size by Color grid with each garment's own cost and MRP; sizes and colors come from lists you can add to (#15, #16).
- Every garment gets its own 12-digit barcode (year and month, lot, serial, check digit); each counter issues from its own lot range so two counters can never clash (#5, #15).
- Print A4 hangtag sheets (3 by 8) with a Code 128 barcode and the price as ₹499.00, with a print preview and a choice of the first free sticker cell (#9, #11, #16).

**Billing**
- A register screen: scan or type a barcode, bill lines on the left, total and payment on the right (#19).
- Price is MRP, then markdown, then cashier discount; a cashier may discount up to 10%, more needs a manager or the owner to type their password; a marked-down garment takes no cashier discount (#7, #8, #19).
- Pay by cash, UPI, card or a mix; change comes only out of cash; bill numbers look like `2026-27/C1/000123` (#17, #19).
- A sold barcode can never be sold twice, and a clear message names the bill that sold it (#18, #19).
- Show the bill on screen and print it on A4; optional customer name and phone on a bill (#18, #19).

**Returns and credit notes**
- Scan the tag to return a garment; a cashier may take it within 7 days, after that a manager or the owner approves; the refund is exactly what was paid (#20, #21, #22).
- Pay the refund by cash, UPI, card, a credit note or an exchange; put the garment back in stock or mark it damaged with a note (#21, #22).
- Credit notes are a barcode that lasts 180 days, keep their balance until used up, print as a slip and can pay part of a later bill (#20, #21, #22).

**Shifts, cash and reports**
- A cashier opens a shift by counting the drawer by notes and coins; sales and returns need an open shift (#23, #24).
- The cash close is blind: the cashier counts and never sees the expected amount or the difference; a shift left open from an earlier day must be closed first (#25).
- The owner's list of closes shows opening, expected and counted cash and short, over or exact (#25).
- A daily report for the owner, one day at a time: sales, bills and garments, money by cash, UPI, card and credit note, refunds, discounts, returns, each shift's cash count, the top 5 styles and profit; totals are checked against the daybook and a warning shows if they disagree (#26, #27, #28).

**Sign-in and roles**
- First-time owner set-up, a lock screen where you pick your name and type a PIN (cashiers, at least 6 digits) or a password (manager and owner, at least 10 characters), wrong-try lockout, a lock after 5 minutes idle and Ctrl+L (#13, #14).
- Cashiers never see costs, margins, reports or the backup screens; manager and owner have every permission (#8, #18, #28).
- Every change writes an audit record; sales, returns, shifts and the daybook can never be edited or deleted, only reversed (#18, #21, #24).

**Protecting the shop's data**
- The database file is encrypted (SQLCipher); the key is kept in the Windows credential store and never in the file or the repository; the app refuses to start on a build without encryption (#29).
- The owner or a manager is shown a recovery key once, writes it down and types the last group back (#29).
- A backup is made when the last open shift of the day is closed and at start-up if none was made today, to a USB drive and a second folder chosen in Manager Mode; the last 60 are kept in each place; if one place is missing the other still gets its copy and the manager is warned (#30, #31, #32).
- Restore a backup in Manager Mode (the owner's password again and RESTORE typed) or on a brand new computer with the recovery key; the data that was there is kept aside until you delete it (#31, #32).

**Installing**
- A Windows installer, `ApparelPoS-Setup-0.9.0.exe`, installs for the current Windows user only (no administrator password), upgrades in place and keeps the shop's data when removed; a portable zip of the app folder is also provided (#33, #34).
- The folder names that decide where Windows keeps the shop's data, and the installer's identity, are pinned by an automatic check so they cannot change by accident (#33).

**Building and checking**
- A browser preview for development on any machine (not for the shop) (#10).
- Automatic checks on every change: unit and screen tests (638 in the shared rules package, 1,067 in the app), document and rule checks, and a Windows build that installs the installer, starts the app and removes it again (#1, #6, #33).

### Security
- The database is encrypted at rest; PINs and passwords are stored only as Argon2id hashes (#13, #29).
- The installer and the app are **not code-signed**: Windows will show a "Windows protected your PC" warning once. Click **More info**, then **Run anyway**. Check the file's SHA-256 against `SHA256SUMS.txt` on the release page if you want to be sure it is the one that was built.

### Known limitations
- **Never run on a real Windows laptop.** Everything was tested on a Mac and on GitHub's Windows build machine, including installing and starting the app there. The Windows credential store, real USB drives and the Windows folder dialogs are untested on real hardware.
- **Never printed on a real printer** and no barcode scanner has been tried; hangtag, bill and credit note slip printing and scanning are untested on real hardware.
- Not built: GST reports that need new data (sales by HSN code, to business customers with a GSTIN, purchases), thermal receipt printing, the shop name, color and logo on the laptop, an owner password reset, a hold bill that survives a lock, sync and the owner's phone app (Release 2). One counter only.
- **GST is built but switched off**, and every GST rule is unverified until your CA confirms it. Take the Settings GST card and the exported reports to your CA first.
- Several more rules were chosen by the assistant and wait for the owner (low stock 2 or fewer, slow mover 30+ days and under 25% sold, a markdown's last day required, a return offsets only its own pay-later bill, and the GST rules). They are listed in the pull requests and the module documents.
- The owner's runbook (`documentation/owner_runbook.md`) was written but has not been followed on a real laptop.
- Tags and bills use a font that covers Latin, Greek and Cyrillic: Hindi (Devanagari) text would print as boxes.
- The app icon is Flutter's default and the company name "Apparel PoS" is a placeholder; the name also decides where Windows keeps the data, so it must be settled **before** go-live and never changed after.
- Several rules were chosen by the assistant and are waiting for the owner's confirmation (listed in `documentation/modules/`): return and credit note details, shift choices, the daily report's profit definition, bill and credit note number limits.
- Billing works with no internet, but nothing is sent to the cloud yet, so the backups on the USB drive and the folder are the only copies.

### Install
1. Download `ApparelPoS-Setup-0.9.0.exe` from the release page and open it. If Windows warns, choose **More info**, then **Run anyway**.
2. Open Apparel PoS and create the owner account. After you sign in, **write the recovery key on paper** and keep it away from the computer.
3. Choose the USB drive and the second folder for backups (Manager Mode, Backups) and press **Back up now**.
4. To remove the program, uninstall it from Windows Settings. The shop's data stays and comes back if you install again.

[Unreleased]: https://github.com/eddy7896/ApparelPOS/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/eddy7896/ApparelPOS/releases/tag/v0.9.0
