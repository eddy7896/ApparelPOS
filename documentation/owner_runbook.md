# Owner's runbook
Status: written 2026-11-23 (P3-3b) from what the app does today. **Nothing in it has been tried on a real Windows laptop yet.** A step marked (check) is one I could not confirm; do it once on the real laptop and fix this guide.

Written for the shop owner, not for a programmer. Short steps, plain words. The version in mind is 0.9.0 (a pre-release).

## 1. The few things to remember
- **Your recovery key and your owner password are written on paper and kept in two safe places.** Lose both the laptop and the recovery key and the shop's data is gone for good. Nobody can get it back, not even the programmer.
- **Back up every day.** The app does it for you when the last shift of the day closes and when it starts, to two places (a USB drive and a second folder). Check the green or yellow bar at the top of Manager Mode now and then.
- **Bills are never edited.** A mistake is put right with a return, a credit note or a new bill. This is on purpose: it keeps the money honest.
- **Cashiers never see cost prices, profit or reports.** Only the manager and the owner do.
- Sign-in: a **cashier** picks their name and types a **6-digit PIN**. A **manager or owner** picks their name and types a **password of at least 10 characters**. Five wrong tries lock that person for 5 minutes (then 10, 20 and so on, up to an hour). The screen locks itself after **5 minutes** without use, and Ctrl+L locks it at once.
- The shop's data lives in `%APPDATA%\Apparel PoS\Apparel PoS` on the laptop, and the key to open it in the Windows credential store. **Uninstalling the app keeps both.**

## 2. Installing
1. On the release page (https://github.com/eddy7896/ApparelPOS/releases) download `ApparelPoS-Setup-<version>.exe`. (No release has been made yet; the owner makes the first one.)
2. Double-click it. It installs for your Windows user only and does not ask for an administrator password.
3. Windows will probably say **"Windows protected your PC"**, because the app is not signed with a paid certificate yet. Click **More info**, then **Run anyway**. This is expected once. (check: the wording on your Windows)
4. Let it put a shortcut on the desktop. Start **Apparel PoS**.
5. To update later, run a newer Setup over the old one. Your data stays.

## 3. The very first start (do this alone, calmly)
1. The first screen asks you to create the **owner**: your name and a password of at least 10 characters. Write the password on paper.
2. The next screen shows the **recovery key**: 16 groups of 4 letters and numbers plus a check group. It is shown **once**. Write every group on paper, exactly. Then type the last group back to prove you copied it. Make a second paper copy and keep the two in different places. Never take a photo of it on a shared phone.
3. You are now in **Manager Mode**. Go to **Backups**. Choose the **USB drive** folder and a **second folder** (another drive, or a folder that a cloud app syncs). Press **Back up now** and read the message: it says how many places got a copy.
4. Set up the shop, in this order:
   - **Settings**: add your categories (for example Men, with Shirts and Jeans inside). Optional, but search and charts are much better with them.
   - **Staff**: add a cashier for each person at the counter (name and a 6-digit PIN). Each gets an operator ID (OP001, OP002...) that prints on the bill instead of their name.
   - **Stock entry**: enter what you have bought (see section 5).
   - Print and stick the **hangtags** (section 5).
5. **The shop name, colour and logo cannot be set on the laptop yet.** They come with the owner's phone app (Release 2). Until then the bill and the hangtags print without a shop name. (This is a known gap; decide before go-live whether that is acceptable.)

## 4. A normal day
**Opening (cashier)**
1. Pick your name, type your PIN. A box asks you to **count the drawer** by notes and coins (use the plus and minus buttons) and open the shift.
2. The register opens. The scan box is always ready.

**Selling**
1. Scan the tag, or type the 12 digits, or type part of the item name and pick the size and colour. The garment goes on the bill. To sell several of one size and colour, use the quantity box or the **+** on the line.
2. Discount: press **Discount** on the line and type `10%` or an amount. A cashier may give up to 10%. More needs a **manager or the owner to type their own password**.
3. Choose **Cash**, **UPI**, **Card**, **Split** or **Pay later** (see below), then press **Complete bill** (or F9). The box that opens shows the **change to give**. Press **P** to print, **Enter** for the next bill.
4. **Hold bill (F4)** puts a bill aside while you serve someone else; **Resume** brings it back. A held bill is lost if the counter locks or the app closes.
5. A garment marked down by the manager shows **Sale 20% off** and takes no discount.
6. **Pay later (udhaar):** only a manager or the owner may allow it (they type their password). The customer's **name and phone number are required**. The customer may pay part now. Later, press **Pay dues** at the register (or **Pay later** in Manager Mode) to take what they bring: it settles their oldest bill first. Only the **owner** can write a debt off, with a reason.

**Returns**
1. Press **Returns**, scan the tag. Inside 7 days the cashier can take it; after that a manager or the owner approves with their password.
2. The refund is exactly what the customer paid. Choose cash, UPI, card, a **credit note** (a barcode slip good for 180 days) or an **Exchange**. A garment from a pay-later bill first reduces what the customer still owes.
3. Mark the garment back in stock, or **Damaged** with a short note.

**Taking a break and closing**
- **Pause** locks the counter for a break; the shift stays open. **Lock** locks it without a break.
- **Close shift** (top bar): count the drawer. The count is **blind**: the app does not tell the cashier what it expected, so nobody is tempted. The owner sees short, over or exact in **Shift closes** and in the **Daily report**.
- Closing the last shift makes the backup. Nobody has to remember.

**Manager and owner, each day**
- **Today** shows sales so far. **Daily report** shows sales, money by cash, UPI and card, refunds, profit, each shift's count and break time. A red warning means the bills and the money ledger disagree: stop and ask the programmer.
- **Stock lookup** shows what is in stock; out of stock is red, running low (2 or fewer) is amber.
- **Analytics** shows 7 and 30 days, busy hours, and slow movers.

## 5. Stock and hangtags
1. **Stock entry**: type the supplier and the style (for example Cotton Kurta), tick the sizes and colours, and for each size and colour type the **quantity, the cost and the MRP**. Pick the category. Save.
2. The app gives **every garment its own 12-digit barcode**. Print the hangtags on A4 sticker sheets (3 by 8). The preview lets you choose the first free sticker cell so a half-used sheet is not wasted. Stick one on each garment.
3. **Markdowns** (Manager Mode): set a percent or an amount off a whole style until a last day. The register applies it by itself.
4. Never change a tag's price by hand: the price on the bill comes from the system.

## 6. GST
GST is **off**. Your CA must confirm every rule (rate, whether prices include tax, rounding, invoice fields) before you switch it on in **Settings > GST** (owner only). Switching it on changes **new** bills only.
- **HSN codes:** type a style's HSN code in Stock entry (GST details) or later in Settings, GST. A style with a different tax rate gets its **own rate** (owner only). A style with no code shows as "No HSN" in the reports.
- **Business buyers:** with GST on, the register has a **Customer GSTIN** box; fill it when a shop buys from you so the invoice and the report carry it.
- **Purchases:** in Stock entry, type the supplier's GSTIN, their invoice number and the **tax you paid** on the purchase, so the report can total your input tax.
- **Reports:** Manager Mode, **GST reports**: pick the days, look at the invoices, returns, tax by rate and by HSN code, sales to business buyers and purchases, then **Export for the CA** writes six spreadsheet files into a folder. How input tax is set off is your CA's decision.

## 7. When something goes wrong
| What happened | What to do |
|---|---|
| A cashier forgot their PIN | Manager Mode > Staff: give them a **new PIN**. |
| A manager forgot their password | The owner gives them a new password in Staff. |
| **The owner forgot the password** | There is no reset yet. Ask the programmer **before** doing anything else. Do not reinstall. (not built) |
| The screen is locked and nobody knows why | It locks after 5 minutes of no use, on Pause and on Ctrl+L. Sign in again. A bill in progress is forgotten when the counter locks. |
| A barcode will not scan | Type the 12 digits, or type part of the item name. If the tag is damaged or will not scan, sell the garment by typing the 12 digits under the bars, or search by name. **Hangtags can only be printed right after a purchase is saved; there is no way yet to print a tag again later** (not built). |
| The scanner types but nothing happens | Click the scan box (F2), try again. The scanner must send Enter after the digits. |
| The printer does nothing | Bills and hangtags print through the normal Windows print dialog. Check that printer works from another program. |
| Wrong item sold, or a mistake on a bill | Do a **return** for the garment and make a new bill. Bills cannot be edited. |
| The cash is short or over at close | Look at **Shift closes**. A small difference can be change given wrongly; a large one needs a talk with the cashier. |
| Power cut while billing | A bill is saved only when **Complete bill** is pressed. A bill not completed is gone, a completed one is safe. Scan the garments again. |
| The yellow bar says no backup today | Plug in the USB drive, open **Backups**, press **Back up now**. |
| **The laptop broke or was stolen** | See "A new laptop" below. |
| The app says the database cannot be opened | Do not delete anything. Restore from the latest backup (below), or call the programmer. |

**A new laptop (or after Windows is reinstalled)**
1. Install Apparel PoS (section 2). On the first screen choose **This is a new computer: restore from a backup** (the link under the owner form).
2. Pick the newest backup file (`apparel-pos-YYYYMMDD-HHMMSS.backup`) from the USB drive or the second folder.
3. Type your **recovery key** (the paper) and, to be sure, the word **RESTORE** in the box.
4. Restart the app. Sign in as usual. Check the last day's report matches what you remember.
5. Set the two backup places again in **Backups**.

**Restoring on a working laptop** (a bad mistake, not a bad bill): Manager Mode > Backups > Restore. It keeps the data you had before, aside, and says so; you can delete the kept data when you are sure.

## 8. Before the shop uses it for real (go-live checklist)
Tick each one **on the real laptop with the real printer and scanner**.
- [ ] Installed from the Setup file; Windows warning clicked through.
- [ ] Owner created; recovery key written twice and stored in two places.
- [ ] Two backup places chosen; **Back up now** worked for both; USB unplugged and plugged back in.
- [ ] **Restore test:** on a second computer (or after reinstalling), restored a backup using only the paper recovery key, and the data was there. (Do this once, for real.)
- [ ] Cashiers added with PINs; each signed in once.
- [ ] A test purchase entered; hangtags printed on the real sticker sheets and the barcode scans.
- [ ] Test bills: cash, UPI, card, split; a discount over 10% with a manager's password; a bill printed on the real printer.
- [ ] A test return, a credit note, and an exchange.
- [ ] A full dry-run day: open, sell, return, pause, close blind, check Shift closes and the Daily report.
- [ ] Decided what to do about the shop name on bills (section 3, step 5).
- [ ] Told your CA about GST and decided when (section 6).
- [ ] Wrote the laptop's Windows password somewhere safe too.

## 9. Not built yet (so do not rely on it)
Second counter or second laptop; the owner's phone and web dashboard; the shop name, colour and logo on the laptop; an owner password reset; a GST filing integration; printing on a thermal receipt printer; printing a hangtag again after the purchase is saved; a receipt for a pay-later payment; hold bill that survives a lock.
