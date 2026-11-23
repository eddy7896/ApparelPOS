// The blind close screen, the forced close of an earlier day's shift, and the
// owner's list of closes. P2-6c, E-SHIFT-1.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/app/ui/shift_closes_screen.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

const managerPassword = 'a long passphrase';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late StockRepository stock;
  late SalesRepository sales;
  late ShiftRepository shifts;
  late SessionController session;
  late AppServices services;
  late String cashierId;
  late String managerId;
  late List<String> barcodes;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId);
    sales = SalesRepository(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    session = SessionController(auth: auth);
    await stock.ensureCounter();
    await stock.seedDefaultOptions();
    cashierId = await auth.createUser(
      name: 'Asha',
      role: Role.cashier,
      secret: '482916',
    );
    managerId = await auth.createUser(
      name: 'Meera',
      role: Role.manager,
      secret: managerPassword,
    );
    final r = await stock.receivePurchase(
      role: Role.owner,
      draft: PurchaseDraft(
        supplier: 'S',
        style: 'Cotton Kurta',
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 3,
            cost: Money(20000),
            mrp: Money(49900),
          ),
        ],
      ),
    );
    final rows = await db
        .customSelect(
          'SELECT barcode_value FROM articles WHERE batch_id = ? ORDER BY barcode_value',
          variables: [Variable<String>(r.batchId)],
        )
        .get();
    barcodes = [for (final x in rows) x.read<String>('barcode_value')];
    services = AppServices(
      stock: stock,
      sales: sales,
      returns: ReturnsRepository(db, newId: newId),
      shifts: shifts,
      reports: ReportRepository(db),
      auth: auth,
      printer: const SystemLabelPrinter(),
      fonts: () async => LabelFonts(
        regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
        bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await tester.pump();
    }
  }

  Future<void> slide(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
  }

  Future<void> open(
    WidgetTester tester, {
    bool manager = false,
    bool withShift = true,
  }) async {
    tester.view.physicalSize = const Size(1500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(
        manager ? managerId : cashierId,
        manager ? managerPassword : '482916',
      );
      if (withShift &&
          await shifts.currentShift(session.user!.userId) == null) {
        await shifts.openShift(
          role: session.user!.role,
          userId: session.user!.userId,
          counts: {Denomination.note500: 4},
        );
      }
    });
    await tester.pumpWidget(PosApp(session: session, services: services));
    await pump(tester);
  }

  Future<void> count(WidgetTester tester, String denom, String n) async {
    await tester.enterText(find.byKey(Key('count-$denom')), n);
    await tester.pump();
  }

  Future<void> closeWith(
    WidgetTester tester,
    Map<String, String> counts,
  ) async {
    await tester.tap(find.byKey(const Key('close-shift-button')));
    await slide(tester);
    for (final e in counts.entries) {
      await count(tester, e.key, e.value);
    }
    await tester.tap(find.byKey(const Key('count-submit')));
    await pump(tester);
    await tester.tap(find.byKey(const Key('confirm-close')));
    await pump(tester);
  }

  Iterable<String> allText(WidgetTester tester) => [
    for (final w in tester.widgetList<Text>(find.byType(Text)))
      w.data ?? w.textSpan?.toPlainText() ?? '',
  ];

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  Future<int> closeCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS c FROM shift_closes')
              .getSingle())
          .read<int>('c');

  group('the Close shift button', () {
    testWidgets('is on the register, enabled with no bill in progress', (
      tester,
    ) async {
      await open(tester);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const Key("close-shift-button")),
            )
            .onPressed,
        isNotNull,
      );
    });
    testWidgets('is off while a bill is in progress', (tester) async {
      await open(tester);
      await tester.enterText(
        find.byKey(const Key('barcode-field')),
        barcodes[0],
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pump(tester);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const Key("close-shift-button")),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('the close screen look', () {
    testWidgets(
      'counts beside a total panel, says the count is blind, and has the green close button',
      (tester) async {
        await open(tester);
        await tester.tap(find.byKey(const Key('close-shift-button')));
        await slide(tester);
        expect(find.text('Close your shift'), findsOneWidget);
        expect(find.text('You have counted'), findsOneWidget);
        expect(find.textContaining('This count is blind.'), findsOneWidget);
        expect(find.text('Close shift and lock'), findsOneWidget);
        await tester.tap(find.byKey(const Key('inc-note500')));
        await tester.pump();
        expect(
          tester.widget<Text>(find.byKey(const Key('count-total'))).data,
          '₹500.00',
        );
      },
    );
  });

  group('closing blind', () {
    testWidgets('Cancel in the confirmation keeps the shift open', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('close-shift-button')));
      await slide(tester);
      await tester.tap(find.byKey(const Key('count-submit')));
      await pump(tester);
      await tester.tap(find.text('Cancel'));
      await pump(tester);
      expect(await tester.runAsync(closeCount), 0);
      expect(find.byKey(const Key('close-shift-title')), findsOneWidget);
    });
    testWidgets(
      'confirming records the close and shows a thank-you, then locks',
      (tester) async {
        await open(tester);
        await closeWith(tester, {'note500': '4'});
        expect(find.byKey(const Key('shift-closed-title')), findsOneWidget);
        expect(await tester.runAsync(closeCount), 1);
        await tester.tap(find.byKey(const Key('lock-after-close')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(session.stage, SessionStage.locked);
      },
    );
    testWidgets(
      'no screen of the close shows the expected amount or the variance (E-SHIFT-1)',
      (tester) async {
        await tester.runAsync(() async {
          await session.start();
          await shifts.openShift(
            role: Role.cashier,
            userId: cashierId,
            counts: {Denomination.note500: 4},
          );
          await sales.saveBill(
            role: Role.cashier,
            cashierId: cashierId,
            lines: [BillLineInput(barcodes[0])],
            payments: [Payment(PaymentMode.cash, Money(49900))],
          );
        });
        await open(tester);
        // expected 2499.00; count only 2400.00 (short 99.00)
        await tester.tap(find.byKey(const Key('close-shift-button')));
        await slide(tester);
        await count(tester, 'note500', '4');
        await count(tester, 'note200', '2');
        final onCount = allText(tester).join(' | ');
        await tester.tap(find.byKey(const Key('count-submit')));
        await pump(tester);
        final onConfirm = allText(tester).join(' | ');
        await tester.tap(find.byKey(const Key('confirm-close')));
        await pump(tester);
        final onDone = allText(tester).join(' | ');
        for (final shown in [onCount, onConfirm, onDone]) {
          expect(shown.toLowerCase(), isNot(contains('expected')));
          expect(shown.toLowerCase(), isNot(contains('variance')));
          expect(shown.toLowerCase(), isNot(contains('short')));
          expect(shown.toLowerCase(), isNot(contains('over ')));
          expect(shown, isNot(contains('2,499.00')));
          expect(shown, isNot(contains('99.00')));
        }
        expect(onCount, contains('₹2,400.00')); // only what was typed
        expect(onCount, contains('You have counted'));
      },
    );
    testWidgets('after the close, signing in again asks for a new shift', (
      tester,
    ) async {
      await open(tester);
      await closeWith(tester, {'note500': '4'});
      await tester.runAsync(() async => session.lock());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => session.signIn(cashierId, '482916'));
      await pump(tester);
      expect(find.byKey(const Key('open-shift-title')), findsOneWidget);
      expect(find.byKey(const Key('barcode-field')), findsNothing);
    });
    testWidgets('a manager can close from Billing too', (tester) async {
      await open(tester, manager: true);
      await tester.tap(find.byKey(const Key('billing-button')));
      await slide(tester);
      await closeWith(tester, {'note500': '4'});
      expect(find.byKey(const Key('shift-closed-title')), findsOneWidget);
    });
  });

  group('a shift left open from an earlier day', () {
    Future<void> leaveOldShift(WidgetTester tester) =>
        tester.runAsync(() async {
          await session.start();
          await ShiftRepository(
            db,
            newId: newId,
            now: () => DateTime.utc(2020, 1, 1, 6),
          ).openShift(
            role: Role.cashier,
            userId: cashierId,
            counts: {Denomination.note500: 2},
          );
        });

    testWidgets('must be closed first: no register until then', (tester) async {
      await leaveOldShift(tester);
      await open(tester, withShift: false);
      expect(find.byKey(const Key('stale-shift-title')), findsOneWidget);
      expect(find.byKey(const Key('barcode-field')), findsNothing);
      expect(find.byKey(const Key('open-shift-title')), findsNothing);
    });
    testWidgets(
      'closing it blind leads to opening a new one, then the register',
      (tester) async {
        await leaveOldShift(tester);
        await open(tester, withShift: false);
        await count(tester, 'note500', '2');
        await tester.tap(find.byKey(const Key('count-submit')));
        await pump(tester);
        expect(await tester.runAsync(closeCount), 1);
        expect(find.byKey(const Key('open-shift-title')), findsOneWidget);
        await count(tester, 'note500', '3');
        await tester.tap(find.byKey(const Key('count-submit')));
        await pump(tester);
        expect(find.byKey(const Key('barcode-field')), findsOneWidget);
      },
    );
    testWidgets('the forced close shows no expected amount either', (
      tester,
    ) async {
      await leaveOldShift(tester);
      await open(tester, withShift: false);
      final shown = allText(tester).join(' | ').toLowerCase();
      expect(shown, isNot(contains('expected')));
      expect(shown, isNot(contains('variance')));
    });
    testWidgets("today's open shift is not stale", (tester) async {
      await open(tester);
      expect(find.byKey(const Key('barcode-field')), findsOneWidget);
      expect(find.byKey(const Key('stale-shift-title')), findsNothing);
    });
  });

  group("the owner's list of closes", () {
    testWidgets('a cashier has no Shift closes button', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('shift-closes-button')), findsNothing);
    });
    testWidgets('empty at first', (tester) async {
      await open(tester, manager: true);
      await tester.tap(find.byKey(const Key('shift-closes-button')));
      await slide(tester);
      expect(find.byKey(const Key('closes-empty')), findsOneWidget);
    });
    testWidgets('shows exact, short and over with the figures, newest first', (
      tester,
    ) async {
      final ids = await tester.runAsync(() async {
        await session.start();
        var now = DateTime.utc(2026, 11, 20, 4);
        final repo = ShiftRepository(db, newId: newId, now: () => now);
        Future<String> run(Map<Denomination, int> counted) async {
          final s = await repo.openShift(
            role: Role.cashier,
            userId: cashierId,
            counts: {Denomination.note500: 4},
          );
          now = now.add(const Duration(hours: 1));
          await repo.closeShift(
            role: Role.cashier,
            userId: cashierId,
            counts: counted,
          );
          now = now.add(const Duration(hours: 1));
          return s.id;
        }

        return [
          await run({Denomination.note500: 4}), // exact 2000.00
          await run({
            Denomination.note500: 3,
            Denomination.note200: 2,
            Denomination.note50: 1,
            Denomination.note20: 2,
            Denomination.coin5: 1,
            Denomination.coin2: 2,
          }), // 1999.00: short 1.00
          await run({
            Denomination.note500: 4,
            Denomination.coin1: 1,
          }), // 2001.00: over 1.00
        ];
      });
      await open(tester, manager: true);
      await tester.tap(find.byKey(const Key('shift-closes-button')));
      await slide(tester);
      expect(find.byKey(const Key('closes-list')), findsOneWidget);
      expect(textOf(tester, 'variance-${ids![0]}'), 'Exact');
      expect(textOf(tester, 'variance-${ids[1]}'), 'Short ₹1.00');
      expect(textOf(tester, 'variance-${ids[2]}'), 'Over ₹1.00');
      expect(
        textOf(tester, 'figures-${ids[1]}'),
        'Opening ₹2,000.00   Expected ₹2,000.00   Counted ₹1,999.00',
      );
      // newest first: the over one (third) is above the exact one (first)
      expect(
        tester.getTopLeft(find.byKey(Key('close-${ids[2]}'))).dy,
        lessThan(tester.getTopLeft(find.byKey(Key('close-${ids[0]}'))).dy),
      );
      expect(find.text('Asha'), findsNWidgets(3));
    });
    testWidgets('expected cash includes the day\'s cash sales and refunds', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await session.start();
        await shifts.openShift(
          role: Role.cashier,
          userId: cashierId,
          counts: {Denomination.note500: 4},
        );
        await sales.saveBill(
          role: Role.cashier,
          cashierId: cashierId,
          lines: [BillLineInput(barcodes[0]), BillLineInput(barcodes[1])],
          payments: [Payment(PaymentMode.cash, Money(99800))],
        );
        await shifts.closeShift(
          role: Role.cashier,
          userId: cashierId,
          counts: {Denomination.note500: 6},
        );
      });
      await open(tester, manager: true);
      await tester.tap(find.byKey(const Key('shift-closes-button')));
      await slide(tester);
      expect(find.textContaining('Expected ₹2,998.00'), findsOneWidget);
      expect(find.textContaining('Counted ₹3,000.00'), findsOneWidget);
      expect(find.textContaining('Over ₹2.00'), findsOneWidget);
    });
    testWidgets('a cashier who reaches the screen anyway is refused', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await session.start();
        await session.signIn(cashierId, '482916');
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ShiftClosesScreen(session: session, services: services),
        ),
      );
      await pump(tester);
      expect(find.byKey(const Key('closes-error')), findsOneWidget);
      expect(find.byKey(const Key('closes-list')), findsNothing);
    });
  });
}
