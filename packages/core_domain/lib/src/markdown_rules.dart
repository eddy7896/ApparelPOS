// A markdown set ahead of time on a whole style (owner, 2026-11-23): a percent
// or a fixed amount off the MRP of every unsold garment of that style, until
// an end date. The register applies it; nobody types it at the counter. Past
// bills keep what they were charged (E-AUDIT-1). Pure rules, no database.
import 'money.dart';
import 'pricing.dart';
import 'report_rules.dart';

/// The furthest ahead an end date may be (a typo such as 2062 is refused).
const int maxMarkdownDays = 366;

/// Why a markdown cannot be set.
enum MarkdownProblem {
  /// A percentage or amount of zero takes nothing off.
  nothingOff,

  /// 100% (or more) would give the garment away.
  percentTooBig,

  /// A fixed amount is not below the cheapest MRP of the style in stock.
  amountTooBig,

  /// The last day is before today.
  endsInPast,

  /// The last day is more than [maxMarkdownDays] days away.
  endsTooFar,
}

/// The reason [cut] cannot be set on a style whose cheapest garment in stock
/// costs [lowestMrp], with the last day [lastDay], today being [today]; null
/// when it is fine. The first problem found is returned.
MarkdownProblem? markdownProblem({
  required PriceCut cut,
  required ShopDay lastDay,
  required ShopDay today,
  required Money lowestMrp,
}) {
  if (cut.isZero) {
    return MarkdownProblem.nothingOff;
  }
  final bp = cut.basisPoints;
  if (bp != null && bp >= 10000) {
    return MarkdownProblem.percentTooBig;
  }
  final amount = cut.amountOff;
  if (amount != null && amount >= lowestMrp) {
    return MarkdownProblem.amountTooBig;
  }
  if (lastDay.compareTo(today) < 0) {
    return MarkdownProblem.endsInPast;
  }
  final days = DateTime.utc(
    lastDay.year,
    lastDay.month,
    lastDay.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  if (days > maxMarkdownDays) {
    return MarkdownProblem.endsTooFar;
  }
  return null;
}

/// The words for a problem, for the screen.
String markdownProblemText(MarkdownProblem p) => switch (p) {
  MarkdownProblem.nothingOff => 'Type a percentage or an amount above zero.',
  MarkdownProblem.percentTooBig => 'A markdown must be under 100%.',
  MarkdownProblem.amountTooBig =>
    'The amount must be less than the cheapest price of this style in stock.',
  MarkdownProblem.endsInPast => 'The last day cannot be before today.',
  MarkdownProblem.endsTooFar =>
    'The last day is more than a year away. Check the date.',
};

/// The markdown that really applies to a garment with [mrp]: [cut] when it
/// leaves something to pay, otherwise null (the garment sells at its MRP). A
/// style's amount can reach a cheaper garment that came into stock later.
PriceCut? effectiveMarkdown(PriceCut? cut, Money mrp) {
  if (cut == null || cut.isZero) {
    return null;
  }
  final amount = cut.amountOff;
  if (amount != null && amount >= mrp) {
    return null;
  }
  return cut;
}

/// True while the markdown applies: up to the end of its last day.
/// [endsBefore] is the India midnight that ends the last day.
bool markdownActive(DateTime endsBefore, DateTime now) =>
    now.toUtc().isBefore(endsBefore.toUtc());

/// The India midnight that ends [lastDay].
DateTime markdownEndsBefore(ShopDay lastDay) => lastDay.endUtc;

/// "20%", "12.5%" or "₹100".
String markdownLabel(PriceCut cut) {
  final bp = cut.basisPoints;
  if (bp != null) {
    final whole = bp ~/ 100;
    final frac = bp % 100;
    if (frac == 0) {
      return '$whole%';
    }
    final f = frac.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '');
    return '$whole.$f%';
  }
  return '₹${_rupees(cut.amountOff!)}';
}

String _rupees(Money m) {
  final rupees = m.paise ~/ 100;
  final paise = m.paise % 100;
  return paise == 0 ? '$rupees' : '$rupees.${paise.toString().padLeft(2, '0')}';
}

/// Reads a date typed as `25/12/2026` (day, month, four-digit year; one or two
/// digits for the day and month). Null for anything else or a date that does
/// not exist.
ShopDay? parseShopDay(String text) {
  final m = RegExp(r'^\s*(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(\d{4})\s*$')
      .firstMatch(text);
  if (m == null) {
    return null;
  }
  try {
    return ShopDay(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
    );
  } on ArgumentError {
    return null;
  }
}

/// `25/12/2026`.
String shopDayText(ShopDay d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// [days] days after [from] (0 is the same day).
ShopDay shopDayPlus(ShopDay from, int days) {
  final d = DateTime.utc(from.year, from.month, from.day + days);
  return ShopDay(d.year, d.month, d.day);
}

/// The last day of [from]'s month.
ShopDay endOfMonth(ShopDay from) {
  final d = DateTime.utc(from.year, from.month + 1, 0);
  return ShopDay(d.year, d.month, d.day);
}
