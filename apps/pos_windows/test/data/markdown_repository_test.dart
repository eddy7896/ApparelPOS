// Markdowns set ahead of time on a style (owner, 2026-11-23): set by a manager
// or owner, applied by the register to every unsold garment of the style until
// the last day, never typed at the counter. E-AUDIT-1, E-AUTHZ-1.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/markdown_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late SalesRepository sales;
  late MarkdownRepository marks;
  late DateTime now;
  late String kurtaId;
  late List<String> kurtaM; // 2 x M Blue at 499
  late List<String> kurtaL; // 1 x L Blue at 599
  late List<String> jeans; // 1 x 1299
  late String jeansId;
  var n = 0;
  String newId() => 'id-${++n}';

  // 12:00 India on 23 Nov 2026
  final today = ShopDay(2026, 11, 23);

  Future<String> idOf(String name) async =>
      (await db
              .customSelect(
                'SELECT id FROM products WHERE name = ?',
                variables: [Variable<String>(name)],
              )
              .getSingle())
          .read<String>('id');

  Future<List<String>> codes(String style, String size) async => [
    for (final r
        in await db
            .customSelect(
              'SELECT a.barcode_value AS b FROM articles a '
              'JOIN variants v ON v.id = a.variant_id '
              'JOIN products p ON p.id = v.product_id '
              'WHERE p.name = ? AND v.size = ? ORDER BY a.barcode_value',
              variables: [Variable<String>(style), Variable<String>(size)],
            )
            .get())
      r.read<String>('b'),
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    now = DateTime.utc(2026, 11, 23, 6, 30);
    stock = StockRepository(db, newId: newId, now: () => now);
    sales = SalesRepository(db, newId: newId, now: () => now);
    marks = MarkdownRepository(db, newId: newId, now: () => now);
    await stock.ensureCounter();
    await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Cotton Kurta',
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 2,
            cost: Money(20000),
            mrp: Money(49900),
          ),
          PurchaseLine(
            size: 'L',
            color: 'Blue',
            quantity: 1,
            cost: Money(25000),
            mrp: Money(59900),
          ),
        ],
      ),
    );
    await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Denim Jeans',
        lines: [
          PurchaseLine(
            size: 'L',
            color: 'Black',
            quantity: 1,
            cost: Money(60000),
            mrp: Money(129900),
          ),
        ],
      ),
    );
    kurtaId = await idOf('Cotton Kurta');
    jeansId = await idOf('Denim Jeans');
    kurtaM = await codes('Cotton Kurta', 'M');
    kurtaL = await codes('Cotton Kurta', 'L');
    jeans = await codes('Denim Jeans', 'L');
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: 'cashier-1',
            name: 'Asha',
            role: 'CASHIER',
            credentialHash: 'x',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await ShiftRepository(
      db,
      newId: newId,
      now: () => now,
    ).openShift(role: Role.cashier, userId: 'cashier-1', counts: const {});
  });
  tearDown(() => db.close());

  Future<void> setPct(
    int bp, {
    ShopDay? last,
    Role? role = Role.manager,
    String? id,
  }) => marks.set(
    role: role,
    actorId: 'm-1',
    productId: id ?? kurtaId,
    cut: PriceCut.percentBp(bp),
    lastDay: last ?? shopDayPlus(today, 7),
  );

  Future<MarkdownStyleEntry> entry(String id) async =>
      (await marks.list(role: Role.manager)).firstWhere((e) => e.id == id);

  Future<SavedBill> sell(
    List<String> barcodes, {
    PriceCut? discount,
    required Money pay,
  }) => sales.saveBill(
    role: Role.cashier,
    cashierId: 'cashier-1',
    lines: [for (final b in barcodes) BillLineInput(b, discount: discount)],
    payments: [Payment(PaymentMode.cash, pay)],
  );

  group('setting a markdown', () {
    test('a manager sets a percent with a last day', () async {
      await setPct(2000, last: ShopDay(2026, 11, 30));
      final e = await entry(kurtaId);
      expect(e.markdown!.cut.basisPoints, 2000);
      expect(shopDayText(e.markdown!.lastDay), '30/11/2026');
      expect(e.markdown!.active, isTrue);
      expect(e.markdown!.setBy, 'm-1');
      expect((await entry(jeansId)).markdown, isNull);
    });

    test('an amount can be set too', () async {
      await marks.set(
        role: Role.owner,
        actorId: 'o-1',
        productId: kurtaId,
        cut: PriceCut.amount(Money(10000)),
        lastDay: shopDayPlus(today, 3),
      );
      final e = await entry(kurtaId);
      expect(e.markdown!.cut.amountOff, Money(10000));
      expect(e.markdown!.cut.basisPoints, isNull);
    });

    test('setting again changes it; there is still one per style', () async {
      await setPct(2000);
      await marks.set(
        role: Role.manager,
        actorId: 'm-1',
        productId: kurtaId,
        cut: PriceCut.amount(Money(5000)),
        lastDay: shopDayPlus(today, 2),
      );
      final e = await entry(kurtaId);
      expect(e.markdown!.cut.amountOff, Money(5000));
      expect(e.markdown!.cut.basisPoints, isNull);
      expect(
        (await db
                .customSelect('SELECT COUNT(*) AS c FROM style_markdowns')
                .getSingle())
            .read<int>('c'),
        1,
      );
    });

    test(
      'changing it keeps when it was first set and notes the change',
      () async {
        await setPct(2000);
        final first = DateTime.utc(2026, 11, 23, 6, 30);
        now = DateTime.utc(2026, 11, 24, 6, 30);
        await setPct(1000);
        final r = await db
            .customSelect('SELECT created_at, updated_at FROM style_markdowns')
            .getSingle();
        expect(r.read<DateTime>('created_at').toUtc(), first);
        expect(r.read<DateTime>('updated_at').toUtc(), now);
      },
    );

    test('remove takes it off, and removing nothing is fine', () async {
      await setPct(2000);
      await marks.remove(
        role: Role.manager,
        actorId: 'm-1',
        productId: kurtaId,
      );
      expect((await entry(kurtaId)).markdown, isNull);
      await marks.remove(
        role: Role.manager,
        actorId: 'm-1',
        productId: kurtaId,
      );
    });

    test('the list shows stock and the price range, by name', () async {
      final all = await marks.list(role: Role.owner);
      expect(all.map((e) => e.name), ['Cotton Kurta', 'Denim Jeans']);
      final k = all.first;
      expect(k.inStock, 3);
      expect(k.lowestMrp, Money(49900));
      expect(k.highestMrp, Money(59900));
    });

    test('a style with nothing in stock shows no range', () async {
      await db.customStatement("UPDATE articles SET status = 'SOLD'");
      final e = await entry(jeansId);
      expect(e.inStock, 0);
      expect(e.lowestMrp, isNull);
      expect(e.highestMrp, isNull);
    });

    test('after the last day it stays listed but not active', () async {
      await setPct(2000, last: today);
      now = DateTime.utc(2026, 11, 23, 18, 29); // 23:59 India
      expect((await entry(kurtaId)).markdown!.active, isTrue);
      now = DateTime.utc(2026, 11, 23, 18, 30); // 00:00 on the 24th
      final e = await entry(kurtaId);
      expect(e.markdown, isNotNull);
      expect(e.markdown!.active, isFalse);
    });
  });

  group('what is refused', () {
    test('a cashier and nobody cannot list, set or remove', () async {
      for (final role in [Role.cashier, null]) {
        await expectLater(
          marks.list(role: role),
          throwsA(isA<PermissionDenied>()),
        );
        await expectLater(
          setPct(2000, role: role),
          throwsA(isA<PermissionDenied>()),
        );
        await expectLater(
          marks.remove(role: role, actorId: 'x', productId: kurtaId),
          throwsA(isA<PermissionDenied>()),
        );
      }
      expect((await entry(kurtaId)).markdown, isNull);
    });

    Future<void> expectProblem(
      Future<void> call,
      MarkdownProblem problem,
    ) async {
      await expectLater(
        call,
        throwsA(
          isA<InvalidMarkdown>().having((e) => e.problem, 'problem', problem),
        ),
      );
    }

    test('nothing off, 100%, a big amount, a past day, a far day', () async {
      await expectProblem(setPct(0), MarkdownProblem.nothingOff);
      await expectProblem(setPct(10000), MarkdownProblem.percentTooBig);
      await expectProblem(
        marks.set(
          role: Role.manager,
          actorId: 'm',
          productId: kurtaId,
          cut: PriceCut.amount(Money(49900)), // not below the cheapest, 499
          lastDay: shopDayPlus(today, 1),
        ),
        MarkdownProblem.amountTooBig,
      );
      await expectProblem(
        setPct(1000, last: today.previous),
        MarkdownProblem.endsInPast,
      );
      await expectProblem(
        setPct(1000, last: shopDayPlus(today, 400)),
        MarkdownProblem.endsTooFar,
      );
      expect((await entry(kurtaId)).markdown, isNull);
    });

    test('an amount just under the cheapest price is fine', () async {
      await marks.set(
        role: Role.manager,
        actorId: 'm',
        productId: kurtaId,
        cut: PriceCut.amount(Money(49899)),
        lastDay: shopDayPlus(today, 1),
      );
      expect((await entry(kurtaId)).markdown, isNotNull);
    });

    test(
      'with nothing in stock the amount is checked against its prices',
      () async {
        await db.customStatement("UPDATE articles SET status = 'SOLD'");
        await expectProblem(
          marks.set(
            role: Role.manager,
            actorId: 'm',
            productId: kurtaId,
            cut: PriceCut.amount(Money(60000)),
            lastDay: shopDayPlus(today, 1),
          ),
          MarkdownProblem.amountTooBig,
        );
      },
    );

    test('a style that does not exist', () async {
      await expectLater(
        setPct(1000, id: 'no-such-style'),
        throwsA(isA<UnknownStyle>()),
      );
    });

    test('a refused markdown leaves the old one and no audit row', () async {
      await setPct(2000);
      await expectLater(setPct(0), throwsA(isA<InvalidMarkdown>()));
      expect((await entry(kurtaId)).markdown!.cut.basisPoints, 2000);
      final audit = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM audit_log WHERE action LIKE 'markdown.%'",
          )
          .getSingle();
      expect(audit.read<int>('c'), 1);
    });
  });

  group('the audit trail', () {
    test('setting and removing are written down', () async {
      await setPct(2000, last: ShopDay(2026, 11, 30));
      await marks.remove(
        role: Role.manager,
        actorId: 'm-1',
        productId: kurtaId,
      );
      final rows = await db
          .customSelect(
            "SELECT action, actor, details FROM audit_log WHERE action LIKE 'markdown.%' ORDER BY rowid",
          )
          .get();
      expect(rows.map((r) => r.read<String>('action')), [
        'markdown.set',
        'markdown.remove',
      ]);
      expect(rows.first.read<String>('actor'), 'm-1');
      expect(rows.first.read<String>('details'), contains('2000'));
      expect(rows.first.read<String>('details'), contains('30/11/2026'));
    });

    test('this file never reads cost', () {
      final text = File('lib/data/markdown_repository.dart').readAsStringSync();
      expect(text.contains('batch_lines'), isFalse);
      expect(text.contains('unit_cost'), isFalse);
    });
  });

  group('at the register', () {
    test('lookup shows the markdown on a garment of the style', () async {
      await setPct(2000);
      final item = await sales.lookup(role: Role.cashier, barcode: kurtaM[0]);
      expect(item!.markdown!.basisPoints, 2000);
      final other = await sales.lookup(role: Role.cashier, barcode: jeans[0]);
      expect(other!.markdown, isNull);
    });

    test('the bill takes it off every garment of the style', () async {
      await setPct(2000);
      // M: 499.00 less 20% = 399.20, L: 599.00 less 20% = 479.20
      final bill = await sell([kurtaM[0], kurtaL[0]], pay: Money(87840));
      expect(bill.lines[0].priced.finalPrice, Money(39920));
      expect(bill.lines[1].priced.finalPrice, Money(47920));
      expect(bill.lines[0].priced.markedDown, isTrue);
      final rows = await db
          .customSelect('SELECT markdown_paise FROM bill_lines ORDER BY rowid')
          .get();
      expect(rows.map((r) => r.read<int>('markdown_paise')), [9980, 11980]);
    });

    test('an amount markdown takes the same rupees off each garment', () async {
      await marks.set(
        role: Role.manager,
        actorId: 'm',
        productId: kurtaId,
        cut: PriceCut.amount(Money(10000)),
        lastDay: shopDayPlus(today, 1),
      );
      final bill = await sell([kurtaM[0], kurtaL[0]], pay: Money(89800));
      expect(bill.lines[0].priced.finalPrice, Money(39900));
      expect(bill.lines[1].priced.finalPrice, Money(49900));
    });

    test('a garment of another style is not touched', () async {
      await setPct(2000);
      final bill = await sell([jeans[0]], pay: Money(129900));
      expect(bill.lines.single.priced.markedDown, isFalse);
    });

    test('a marked-down garment takes no cashier discount', () async {
      await setPct(2000);
      await expectLater(
        sell([kurtaM[0]], discount: PriceCut.percentBp(500), pay: Money(39920)),
        throwsA(isA<DiscountNotAllowed>()),
      );
      final status = await db
          .customSelect(
            'SELECT status FROM articles WHERE barcode_value = ?',
            variables: [Variable<String>(kurtaM[0])],
          )
          .getSingle();
      expect(status.read<String>('status'), 'IN_STOCK');
    });

    test('on the last day it applies, the next day the MRP is back', () async {
      await setPct(2000, last: today);
      now = DateTime.utc(2026, 11, 23, 18, 29);
      expect(
        (await sales.lookup(role: Role.cashier, barcode: kurtaM[0]))!.markdown,
        isNotNull,
      );
      now = DateTime.utc(2026, 11, 23, 18, 30);
      expect(
        (await sales.lookup(role: Role.cashier, barcode: kurtaM[0]))!.markdown,
        isNull,
      );
      final bill = await sell([kurtaM[0]], pay: Money(49900));
      expect(bill.lines.single.priced.markedDown, isFalse);
    });

    test('removing it puts the MRP back at once', () async {
      await setPct(2000);
      await marks.remove(role: Role.manager, actorId: 'm', productId: kurtaId);
      final bill = await sell([kurtaM[0]], pay: Money(49900));
      expect(bill.lines.single.priced.markedDown, isFalse);
    });

    test(
      'an amount as big as a cheaper garment is ignored for that garment',
      () async {
        await marks.set(
          role: Role.manager,
          actorId: 'm',
          productId: kurtaId,
          cut: PriceCut.amount(Money(30000)),
          lastDay: shopDayPlus(today, 1),
        );
        // a cheaper garment of the style arrives later, MRP 250.00
        await stock.receivePurchase(
          role: Role.owner,
          draft: PurchaseDraft(
            supplier: 'S',
            style: 'Cotton Kurta',
            lines: [
              PurchaseLine(
                size: 'S',
                color: 'Blue',
                quantity: 1,
                cost: Money(10000),
                mrp: Money(25000),
              ),
            ],
          ),
        );
        final cheap = (await codes('Cotton Kurta', 'S')).single;
        final item = await sales.lookup(role: Role.cashier, barcode: cheap);
        expect(item!.markdown, isNull);
        final bill = await sell([cheap], pay: Money(25000));
        expect(bill.lines.single.priced.finalPrice, Money(25000));
        // the dearer ones still get it
        final m = await sales.lookup(role: Role.cashier, barcode: kurtaM[0]);
        expect(m!.markdown!.amountOff, Money(30000));
      },
    );

    test(
      'changing or removing a markdown never changes a bill already made',
      () async {
        await setPct(2000);
        await sell([kurtaM[0]], pay: Money(39920));
        await marks.remove(
          role: Role.manager,
          actorId: 'm',
          productId: kurtaId,
        );
        await setPct(5000);
        final row = await db
            .customSelect('SELECT markdown_paise FROM bill_lines')
            .getSingle();
        expect(row.read<int>('markdown_paise'), 9980);
        final total = await db
            .customSelect('SELECT total_paise FROM bills')
            .getSingle();
        expect(total.read<int>('total_paise'), 39920);
      },
    );

    test('a cashier cannot set a markdown by passing one in', () async {
      await expectLater(
        sales.saveBill(
          role: Role.cashier,
          cashierId: 'cashier-1',
          lines: [BillLineInput(kurtaM[0], markdown: PriceCut.percentBp(5000))],
          payments: [Payment(PaymentMode.cash, Money(24950))],
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });
}
