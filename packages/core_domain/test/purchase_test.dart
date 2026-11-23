// Entering a purchase (GRN): the Size x Color grid where every cell has its own
// quantity, cost and MRP (owner, 2026-11-20). Barcodes come from the counter's
// current lot, which keeps filling until full (owner, 2026-11-20).
import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

PurchaseLine line(
  String size,
  String color,
  int qty, {
  int cost = 20000,
  int mrp = 49900,
}) => PurchaseLine(
  size: size,
  color: color,
  quantity: qty,
  cost: Money(cost),
  mrp: Money(mrp),
);

PurchaseDraft draft(
  List<PurchaseLine> lines, {
  String supplier = 'Sample Supplier',
  String style = 'Cotton Kurta',
}) => PurchaseDraft(supplier: supplier, style: style, lines: lines);

Set<PurchaseProblem> problems(PurchaseDraft d) =>
    checkPurchase(d).where((i) => !i.isWarning).map((i) => i.problem).toSet();

void main() {
  group('checkPurchase', () {
    test('a good purchase has no problems and no warnings', () {
      expect(
        checkPurchase(draft([line('M', 'Blue', 5), line('L', 'Blue', 3)])),
        isEmpty,
      );
    });

    test('supplier and style must not be blank', () {
      expect(problems(draft([line('M', 'Blue', 1)], supplier: '  ')), {
        PurchaseProblem.blankSupplier,
      });
      expect(problems(draft([line('M', 'Blue', 1)], style: '')), {
        PurchaseProblem.blankStyle,
      });
    });

    test('there must be at least one line', () {
      expect(problems(draft([])), {PurchaseProblem.noLines});
    });

    test('each line needs a size, a color and a quantity of at least 1', () {
      expect(problems(draft([line(' ', 'Blue', 1)])), {
        PurchaseProblem.blankSize,
      });
      expect(problems(draft([line('M', '', 1)])), {PurchaseProblem.blankColor});
      expect(problems(draft([line('M', 'Blue', 0)])), {
        PurchaseProblem.badQuantity,
      });
      expect(problems(draft([line('M', 'Blue', -2)])), {
        PurchaseProblem.badQuantity,
      });
    });

    test('the issue names the line it is about', () {
      final issues = checkPurchase(
        draft([line('M', 'Blue', 1), line('L', 'Blue', 0)]),
      );
      expect(issues.single.lineIndex, 1);
    });

    test(
      'the same size and color twice is refused, ignoring case and spaces',
      () {
        expect(
          problems(draft([line('M', 'Blue', 1), line(' m ', 'blue', 2)])),
          {PurchaseProblem.duplicateLine},
        );
      },
    );

    test('negative cost or MRP is refused', () {
      expect(problems(draft([line('M', 'Blue', 1, cost: -1)])), {
        PurchaseProblem.negativeMoney,
      });
      expect(problems(draft([line('M', 'Blue', 1, mrp: -1)])), {
        PurchaseProblem.negativeMoney,
      });
    });

    test('more garments than one lot can hold is refused', () {
      expect(
        problems(draft([line('M', 'Blue', 10000), line('L', 'Blue', 1)])),
        {PurchaseProblem.tooManyForOneLot},
      );
      expect(problems(draft([line('M', 'Blue', 10000)])), isEmpty);
    });

    test('an MRP below the cost is a warning, not a problem', () {
      final issues = checkPurchase(
        draft([line('M', 'Blue', 1, cost: 60000, mrp: 49900)]),
      );
      expect(issues.single.problem, PurchaseProblem.mrpBelowCost);
      expect(issues.single.isWarning, isTrue);
      expect(issues.single.lineIndex, 0);
    });
  });

  group('GST details of a purchase (unverified until the CA confirms)', () {
    PurchaseDraft with_({
      String hsn = '',
      int? rate,
      String gstin = '',
      String invoice = '',
      int tax = 0,
    }) => PurchaseDraft(
      supplier: 'S',
      style: 'Cotton Kurta',
      lines: [line('M', 'Blue', 1)],
      hsn: hsn,
      styleGstBp: rate,
      supplierGstin: gstin,
      invoiceNo: invoice,
      inputTax: Money(tax),
    );

    test('all of them are optional', () {
      expect(checkPurchase(with_()), isEmpty);
      expect(
        checkPurchase(
          with_(
            hsn: '6109',
            rate: 1200,
            gstin: '27abcde1234f1z5',
            invoice: 'INV/2026/17',
            tax: 12000,
          ),
        ),
        isEmpty,
      );
    });
    test('an HSN code that is not 4 to 8 digits is refused', () {
      expect(problems(with_(hsn: '61')), {PurchaseProblem.badHsn});
      expect(problems(with_(hsn: '6109x')), {PurchaseProblem.badHsn});
      expect(problems(with_(hsn: '610910000')), {PurchaseProblem.badHsn});
    });
    test('a supplier GSTIN must be GSTIN-shaped when typed', () {
      expect(problems(with_(gstin: 'nope')), {
        PurchaseProblem.badSupplierGstin,
      });
    });
    test('the invoice number has a length limit', () {
      expect(problems(with_(invoice: 'x' * 40)), isEmpty);
      expect(problems(with_(invoice: 'x' * 41)), {
        PurchaseProblem.invoiceNoTooLong,
      });
    });
    test('the style rate is 0 to 50%', () {
      expect(problems(with_(rate: 0)), isEmpty);
      expect(problems(with_(rate: 5000)), isEmpty);
      expect(problems(with_(rate: 5001)), {PurchaseProblem.badStyleRate});
      expect(problems(with_(rate: -1)), {PurchaseProblem.badStyleRate});
    });
    test('tax paid cannot be negative', () {
      expect(problems(with_(tax: -1)), {PurchaseProblem.negativeMoney});
    });
  });

  group('planPurchase', () {
    final cursor = LotCursor.start(LotRange(0, 499));

    test('gives every garment its own barcode, in line order', () {
      final plan = planPurchase(
        draft([line('M', 'Blue', 2), line('L', 'Red', 3)]),
        cursor,
        year: 26,
        month: 11,
      );
      expect(plan.articles.length, 5);
      expect(plan.articles.map((a) => (a.size, a.color)), [
        ('M', 'Blue'),
        ('M', 'Blue'),
        ('L', 'Red'),
        ('L', 'Red'),
        ('L', 'Red'),
      ]);
      expect(plan.articles.map((a) => a.barcode.serial), [0, 1, 2, 3, 4]);
      expect(plan.articles.map((a) => a.barcode.lot).toSet(), {0});
      expect(plan.articles.map((a) => a.barcode.value).toSet().length, 5);
      expect(
        plan.articles.every(
          (a) => a.barcode.year == 26 && a.barcode.month == 11,
        ),
        isTrue,
      );
    });

    test('each garment keeps its own line MRP', () {
      final plan = planPurchase(
        draft([
          line('M', 'Blue', 1, mrp: 49900),
          line('XL', 'Blue', 1, mrp: 54900),
        ]),
        cursor,
        year: 26,
        month: 11,
      );
      expect(plan.articles.map((a) => a.mrp.paise), [49900, 54900]);
    });

    test('the new cursor continues after the last serial', () {
      final plan = planPurchase(
        draft([line('M', 'Blue', 5)]),
        cursor,
        year: 26,
        month: 11,
      );
      expect(plan.cursor.lot, 0);
      expect(plan.cursor.nextSerial, 5);
      final second = planPurchase(
        draft([line('M', 'Blue', 2)]),
        plan.cursor,
        year: 26,
        month: 11,
      );
      expect(second.articles.first.barcode.serial, 5);
    });

    test('keeps filling the current lot', () {
      final c = planPurchase(
        draft([line('M', 'Blue', 9000)]),
        cursor,
        year: 26,
        month: 11,
      ).cursor;
      final plan = planPurchase(
        draft([line('M', 'Blue', 1000)]),
        c,
        year: 26,
        month: 11,
      );
      expect(plan.lot, 0);
      expect(plan.cursor.nextSerial, 10000);
    });

    test('a purchase that does not fit moves to the next lot whole, never splitting', () {
      final c = planPurchase(
        draft([line('M', 'Blue', 9000)]),
        cursor,
        year: 26,
        month: 11,
      ).cursor;
      final plan = planPurchase(
        draft([line('M', 'Blue', 1001)]),
        c,
        year: 26,
        month: 11,
      );
      expect(plan.lot, 1);
      expect(plan.articles.map((a) => a.barcode.lot).toSet(), {1});
      expect(plan.articles.first.barcode.serial, 0);
      expect(plan.cursor.lot, 1);
      expect(plan.cursor.nextSerial, 1001);
    });

    test('running out of lots is reported, nothing is planned', () {
      final last = LotCursor.start(LotRange(499, 499));
      final full = planPurchase(
        draft([line('M', 'Blue', 10000)]),
        last,
        year: 26,
        month: 11,
      ).cursor;
      expect(
        () => planPurchase(
          draft([line('M', 'Blue', 1)]),
          full,
          year: 26,
          month: 11,
        ),
        throwsA(isA<RangeExhausted>()),
      );
    });

    test('a purchase with problems cannot be planned', () {
      expect(
        () => planPurchase(draft([]), cursor, year: 26, month: 11),
        throwsArgumentError,
      );
    });

    test('cleans up names: trimmed size, color, style and supplier', () {
      final plan = planPurchase(
        draft(
          [line(' M ', ' Blue ', 1)],
          style: '  Cotton Kurta ',
          supplier: ' Sample Supplier ',
        ),
        cursor,
        year: 26,
        month: 11,
      );
      expect(plan.articles.single.size, 'M');
      expect(plan.articles.single.color, 'Blue');
      expect(plan.style, 'Cotton Kurta');
      expect(plan.supplier, 'Sample Supplier');
    });

    test('quantity per line and cost are carried for the batch lines', () {
      final plan = planPurchase(
        draft([line('M', 'Blue', 4, cost: 21000)]),
        cursor,
        year: 26,
        month: 11,
      );
      expect(plan.lines.single.quantity, 4);
      expect(plan.lines.single.cost, const Money(21000));
    });
  });

  group('shop year and month (Asia/Kolkata, ADR-0007)', () {
    test('uses India time, which is 5 hours 30 minutes ahead of UTC', () {
      expect(shopYearMonth(DateTime.utc(2026, 11, 20, 10)), (26, 11));
      expect(shopYearMonth(DateTime.utc(2026, 11, 30, 20)), (
        26,
        12,
      )); // 1 Dec, 01:30 in India
      expect(shopYearMonth(DateTime.utc(2026, 12, 31, 19)), (
        27,
        1,
      )); // 1 Jan 2027, 00:30 in India
      expect(shopYearMonth(DateTime.utc(2026, 11, 30, 18, 29)), (26, 11));
      expect(shopYearMonth(DateTime.utc(2026, 11, 30, 18, 30)), (26, 12));
    });
    test('two digit year wraps at 100', () {
      expect(shopYearMonth(DateTime.utc(2100, 6, 1)), (0, 6));
    });
  });
}
