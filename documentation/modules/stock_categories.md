# Module: stock categories
Status: built 2026-11-23 (Release 1 counter app). Owner decisions, 2026-11-23: two levels; styles are put in a category when stock is entered and can be changed in Settings; the owner and a manager set them up; categories are used in the stock lookup filter, the billing search, the analytics trend and the sell-through.

## How it works
- **Two levels:** a group (Men) and categories inside it (Shirts, Jeans). A group with no categories can be used as a category itself. A group with categories under it takes no styles directly, and a category cannot have categories inside it. A group that already has styles in it cannot get a category until those styles are moved.
- **Names:** 1 to 40 characters, unique among the same group (capitals ignored). Removing needs the group or category to be empty (no styles, no categories).
- **Setup:** "Settings" in the Manager Mode left menu (owner and manager). It lists the groups and categories (add, rename, remove) and every style with a category box, with a "No category" filter for styles still to be sorted.
- **Stock entry:** an optional Category box (only places that can take styles are listed). A style that already exists shows its category; the person can change it.
- **Quick lookup:** the Stock lookup screen and the billing name search show category chips (All, each group, No category; a group opens the categories inside it). Cashiers see them too.
- **Analytics:** "Sales by category" (groups or categories, this period against the period before, with the change), a trend reading naming the fastest growing and most falling group, and a By category view of sell-through with slow movers counted. The daily report has a "Sales by category" chart and table for the day.
- **History follows the style:** sales are attributed through the style's current category, so putting a style in another category re-labels its past sales in these views.

## Where it is
`packages/core_domain/lib/src/category_rules.dart` (names, two levels, assignable, filter, roll-up), `apps/pos_windows/lib/data/category_repository.dart`, schema v9 (`categories` table and `products.category_id`), `settings_screen.dart`, `category_chips.dart`.

## Not built
Moving a whole category's styles to another in one step; ordering categories by hand (they are sorted by name); category colors; categories on the owner's phone app and web (Release 2).
