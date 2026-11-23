// GST reports for the owner's CA (P3-4, second step): the invoice register, the
// returns register, tax by rate, a day-by-day summary, and CSV text to open in a
// spreadsheet. UNVERIFIED until the CA confirms which reports and columns they
// need (SSOT rule 14). Built only from what bills and returns already store:
// the tax on each bill line (so a later change of rate or mode never alters a
// past figure). Not built: HSN sales, sales to business customers with a
// customer GSTIN, purchases and input tax (the data is not captured yet).
// Needs `viewReports`. No cost is read.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// One GST invoice (a bill with tax on it).
final class GstInvoiceRow {
  const GstInvoiceRow({
    required this.billNo,
    required this.day,
    required this.customer,
    required this.rateBp,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.total,
  });
  final String billNo;
  final ShopDay day;
  final String customer;

  /// The rate, or null when the bill's garments had different rates.
  final int? rateBp;
  final Money taxable;
  final Money cgst;
  final Money sgst;

  /// What the customer paid.
  final Money total;
  Money get tax => cgst + sgst;
}

/// One return of garments that carried tax.
final class GstReturnRow {
  const GstReturnRow({
    required this.billNos,
    required this.day,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.refund,
  });

  /// The bills the garments were sold on, comma separated.
  final String billNos;
  final ShopDay day;
  final Money taxable;
  final Money cgst;
  final Money sgst;
  final Money refund;
  Money get tax => cgst + sgst;
}

/// Sales and returns at one rate.
final class GstRateRow {
  const GstRateRow({
    required this.rateBp,
    required this.taxable,
    required this.tax,
    required this.returnedTaxable,
    required this.returnedTax,
  });
  final int rateBp;
  final Money taxable;
  final Money tax;
  final Money returnedTaxable;
  final Money returnedTax;
  Money get netTaxable => taxable - returnedTaxable;
  Money get netTax => tax - returnedTax;
}

/// One day of the summary.
final class GstDayRow {
  const GstDayRow({
    required this.day,
    required this.invoices,
    required this.taxable,
    required this.tax,
    required this.returnedTax,
  });
  final ShopDay day;
  final int invoices;
  final Money taxable;
  final Money tax;
  final Money returnedTax;
  Money get netTax => tax - returnedTax;
}

/// The GST reports for a range of days.
final class GstReport {
  const GstReport({
    required this.from,
    required this.to,
    required this.invoices,
    required this.returns,
    required this.byRate,
    required this.byDay,
    required this.billsWithoutGst,
  });
  final ShopDay from;
  final ShopDay to;
  final List<GstInvoiceRow> invoices;
  final List<GstReturnRow> returns;
  final List<GstRateRow> byRate;
  final List<GstDayRow> byDay;

  /// Bills in the range made while GST was off (no tax; not in the registers).
  final int billsWithoutGst;

  Money get taxable =>
      invoices.fold<Money>(Money.zero, (s, i) => s + i.taxable);
  Money get tax => invoices.fold<Money>(Money.zero, (s, i) => s + i.tax);
  Money get returnedTax => returns.fold<Money>(Money.zero, (s, r) => s + r.tax);
  Money get netTax => tax - returnedTax;

  static String _rate(int? bp) =>
      bp == null ? 'mixed' : markdownLabel(PriceCut.percentBp(bp));

  /// The invoice register as CSV text (a header line, then one line each).
  String invoicesCsv() => [
    csvRow([
      'Invoice no',
      'Date',
      'Customer',
      'GST rate',
      'Taxable value',
      'CGST',
      'SGST',
      'Total tax',
      'Invoice total',
    ]),
    for (final i in invoices)
      csvRow([
        i.billNo,
        shopDayText(i.day),
        i.customer,
        _rate(i.rateBp),
        plainRupees(i.taxable),
        plainRupees(i.cgst),
        plainRupees(i.sgst),
        plainRupees(i.tax),
        plainRupees(i.total),
      ]),
  ].join('\r\n');

  /// The returns register as CSV text.
  String returnsCsv() => [
    csvRow([
      'Date',
      'Original invoice no',
      'Taxable value returned',
      'CGST returned',
      'SGST returned',
      'Total tax returned',
      'Refund',
    ]),
    for (final r in returns)
      csvRow([
        shopDayText(r.day),
        r.billNos,
        plainRupees(r.taxable),
        plainRupees(r.cgst),
        plainRupees(r.sgst),
        plainRupees(r.tax),
        plainRupees(r.refund),
      ]),
  ].join('\r\n');

  /// Tax by rate and by day as CSV text (two blocks, a blank line between).
  String summaryCsv() => [
    csvRow([
      'GST rate',
      'Taxable value',
      'Tax',
      'Taxable value returned',
      'Tax returned',
      'Net taxable value',
      'Net tax',
    ]),
    for (final r in byRate)
      csvRow([
        _rate(r.rateBp),
        plainRupees(r.taxable),
        plainRupees(r.tax),
        plainRupees(r.returnedTaxable),
        plainRupees(r.returnedTax),
        plainRupees(r.netTaxable),
        plainRupees(r.netTax),
      ]),
    '',
    csvRow([
      'Date',
      'Invoices',
      'Taxable value',
      'Tax',
      'Tax returned',
      'Net tax',
    ]),
    for (final d in byDay)
      csvRow([
        shopDayText(d.day),
        '${d.invoices}',
        plainRupees(d.taxable),
        plainRupees(d.tax),
        plainRupees(d.returnedTax),
        plainRupees(d.netTax),
      ]),
  ].join('\r\n');
}

class GstReportRepository {
  GstReportRepository(this._db);
  final AppDatabase _db;

  /// The reports for [from] to [to] (both included, India days). Needs
  /// `viewReports`. Throws [PermissionDenied], or [ArgumentError] when [to] is
  /// before [from].
  Future<GstReport> report({
    required Role? role,
    required ShopDay from,
    required ShopDay to,
  }) async {
    require(role, Permission.viewReports);
    if (to.compareTo(from) < 0) {
      throw ArgumentError('the last day is before the first day');
    }
    final start = Variable<DateTime>(from.startUtc);
    final end = Variable<DateTime>(to.endUtc);

    final inv = await _db
        .customSelect(
          'SELECT b.bill_no AS no, b.billed_at AS at, b.customer_name AS who, '
          'b.total_paise AS total, MIN(l.gst_bp) AS lo, MAX(l.gst_bp) AS hi, '
          'SUM(l.taxable_paise) AS taxable, SUM(l.tax_paise) AS tax, '
          'SUM((l.tax_paise + 1) / 2) AS cgst '
          'FROM bills b JOIN bill_lines l ON l.bill_id = b.id '
          'WHERE b.billed_at >= ? AND b.billed_at < ? '
          'GROUP BY b.id HAVING MAX(l.gst_bp) > 0 '
          'ORDER BY b.billed_at, b.rowid',
          variables: [start, end],
        )
        .get();
    final invoices = [
      for (final r in inv)
        GstInvoiceRow(
          billNo: r.read<String>('no'),
          day: ShopDay.fromUtc(r.read<DateTime>('at')),
          customer: r.read<String?>('who') ?? '',
          rateBp: r.read<int>('lo') == r.read<int>('hi')
              ? r.read<int>('hi')
              : null,
          taxable: Money(r.read<int>('taxable')),
          cgst: Money(r.read<int>('cgst')),
          sgst: Money(r.read<int>('tax') - r.read<int>('cgst')),
          total: Money(r.read<int>('total')),
        ),
    ];

    final ret = await _db
        .customSelect(
          'SELECT r.id AS id, r.returned_at AS at, r.total_paise AS refund, '
          "group_concat(DISTINCT b.bill_no) AS nos, "
          'SUM(bl.taxable_paise) AS taxable, SUM(bl.tax_paise) AS tax, '
          'SUM((bl.tax_paise + 1) / 2) AS cgst '
          'FROM returns r JOIN return_lines rl ON rl.return_id = r.id '
          'JOIN bill_lines bl ON bl.id = rl.bill_line_id '
          'JOIN bills b ON b.id = bl.bill_id '
          'WHERE r.returned_at >= ? AND r.returned_at < ? '
          'GROUP BY r.id HAVING SUM(bl.tax_paise) > 0 '
          'ORDER BY r.returned_at, r.rowid',
          variables: [start, end],
        )
        .get();
    final returns = [
      for (final r in ret)
        GstReturnRow(
          billNos: (r.read<String>('nos')).split(',').join(', '),
          day: ShopDay.fromUtc(r.read<DateTime>('at')),
          taxable: Money(r.read<int>('taxable')),
          cgst: Money(r.read<int>('cgst')),
          sgst: Money(r.read<int>('tax') - r.read<int>('cgst')),
          refund: Money(r.read<int>('refund')),
        ),
    ];

    final rateSales = await _db
        .customSelect(
          'SELECT l.gst_bp AS bp, SUM(l.taxable_paise) AS taxable, '
          'SUM(l.tax_paise) AS tax FROM bill_lines l '
          'JOIN bills b ON b.id = l.bill_id '
          'WHERE b.billed_at >= ? AND b.billed_at < ? AND l.gst_bp > 0 '
          'GROUP BY l.gst_bp',
          variables: [start, end],
        )
        .get();
    final rateReturns = await _db
        .customSelect(
          'SELECT bl.gst_bp AS bp, SUM(bl.taxable_paise) AS taxable, '
          'SUM(bl.tax_paise) AS tax FROM return_lines rl '
          'JOIN returns r ON r.id = rl.return_id '
          'JOIN bill_lines bl ON bl.id = rl.bill_line_id '
          'WHERE r.returned_at >= ? AND r.returned_at < ? AND bl.gst_bp > 0 '
          'GROUP BY bl.gst_bp',
          variables: [start, end],
        )
        .get();
    final sold = {
      for (final r in rateSales)
        r.read<int>('bp'): (r.read<int>('taxable'), r.read<int>('tax')),
    };
    final back = {
      for (final r in rateReturns)
        r.read<int>('bp'): (r.read<int>('taxable'), r.read<int>('tax')),
    };
    final rates = {...sold.keys, ...back.keys}.toList()..sort();
    final byRate = [
      for (final bp in rates)
        GstRateRow(
          rateBp: bp,
          taxable: Money(sold[bp]?.$1 ?? 0),
          tax: Money(sold[bp]?.$2 ?? 0),
          returnedTaxable: Money(back[bp]?.$1 ?? 0),
          returnedTax: Money(back[bp]?.$2 ?? 0),
        ),
    ];

    final days = <ShopDay>{
      for (final i in invoices) i.day,
      for (final r in returns) r.day,
    }.toList()..sort((a, b) => a.compareTo(b));
    final byDay = [
      for (final d in days)
        GstDayRow(
          day: d,
          invoices: invoices.where((i) => i.day.compareTo(d) == 0).length,
          taxable: invoices
              .where((i) => i.day.compareTo(d) == 0)
              .fold<Money>(Money.zero, (s, i) => s + i.taxable),
          tax: invoices
              .where((i) => i.day.compareTo(d) == 0)
              .fold<Money>(Money.zero, (s, i) => s + i.tax),
          returnedTax: returns
              .where((r) => r.day.compareTo(d) == 0)
              .fold<Money>(Money.zero, (s, r) => s + r.tax),
        ),
    ];

    final none = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM bills b WHERE b.billed_at >= ? '
          'AND b.billed_at < ? AND NOT EXISTS (SELECT 1 FROM bill_lines l '
          'WHERE l.bill_id = b.id AND l.gst_bp > 0)',
          variables: [start, end],
        )
        .getSingle();
    return GstReport(
      from: from,
      to: to,
      invoices: invoices,
      returns: returns,
      byRate: byRate,
      byDay: byDay,
      billsWithoutGst: none.read<int>('c'),
    );
  }
}
