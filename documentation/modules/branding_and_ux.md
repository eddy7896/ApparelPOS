# Module: branding and counter UX redesign
Status: Plan, nothing built (2026-11-22). A clickable mock-up exists: https://claude.ai/artifact/B9CuSG1C9xeBMQx9Yb98mk (private to the owner; sample data and placeholder look)

Purpose: a faster, clearer, touch and keyboard friendly counter, and a look (shop name, colors, logo) that is **data, not code**, so each shop can have its own.

## Owner decisions (2026-11-22)
- **Goals:** faster billing at the counter (scan first, big totals, fewer clicks); a branded look; easier for a new cashier (clear labels, helpful messages); a better owner experience (navigation, reports, stock, settings easier to find).
- **Devices:** mouse and keyboard with a barcode scanner, and touch. Click targets are at least 48 dp (owner, Q1, 2026-11-17); the first mock-up used 44 px in places and must be corrected.
- **Language:** English only for now.
- **Review:** a clickable mock-up first, then the owner approves, then it is built screen by screen. Each pull request carries before and after screenshots.
- **Branding is not hard-coded.** Shop name, main color and logo are settings in the database (`app_settings`), read at run time; the app ships with a placeholder name, color and logo.
- **Who sets them:** the owner's mobile app (Release 2, with sync). Until it exists the colors and logo stay at the placeholder and **there is no branding settings screen** in the Windows app. The shop name stays settable through the existing prompt the first time hangtags are printed (owner, 2026-11-22).
- **Colors:** one main color chosen from a set of tested ones or typed as a color code; the app checks it is readable (enough contrast with white text) and builds the rest of the palette. Free colors for every element are not allowed.
- **Where the name and logo appear:** sign-in and the top bar; printed bills and credit note slips; hangtags (name; logo only if room); report headings and the Backups screen. **Backup file names stay generic** (`apparel-pos-DATE-TIME.backup`): the 60-copy pruning finds backups only by that exact pattern and must never touch other files on the drive (owner, 2026-11-22).

## Rules to respect
- The Windows **data folder does not follow the shop name**. It comes from `CompanyName` and `ProductName` in `Runner.rc` (ADR-0018, `npm run check:data-location`); the shop's display name is a setting only. Renaming the shop must never move the database.
- Branding settings are shop data: backed up with the database, restored with it, and (Release 2) synced from the owner's phone. Only manager and owner may change them (`manageSettings`).
- A logo is shown only if it is a PNG or JPEG within a size limit; a bad file falls back to the placeholder, never breaks a screen. Limits to be set when built (assistant's proposal: 256 KB, up to 512 by 512 px).
- Hangtags and bills keep the existing rule that text must fit; a long shop name is shortened with an ellipsis.

## Plan
| ID | Task | Needs |
|---|---|---|
| UX-1 | Branding contract: rules in `core_domain` (name length, color readability, palette from one color, logo limits), settings keys with placeholder defaults, a `BrandRepository`, the app theme built from it; name and logo shown in the top bars, sign-in, bills, slips, tags, report headings and the Backups screen; a development-only preview editor (like the practice users) so the look can be tried in the browser | owner's go-ahead |
| UX-2 | Register: scan first, big total, quick cash amounts, change shown big, 48 dp targets, keyboard shortcuts | owner approves the mock-up |
| UX-3 | Sign-in, open shift and blind close for touch | mock-up approved |
| UX-4 | Manager navigation and home; report and backup polish | mock-up approved |
| UX-5 | Returns and stock entry restyle | mock-up approved |
| P4 | The owner's mobile app edits branding; sync writes it to the counter | Release 2 |

## Not decided yet
- The real shop name, colors and logo (placeholders only; the shop name also must be chosen before go-live because of the Windows identity, ADR-0018 D9).
- Which mock-up changes the owner wants.
- Whether proposed features in the mock-up (low-stock list, keyboard shortcuts, "Needs a look") are wanted; they do not exist today.
