// The returns screen, the credit note slip text, and credit notes at the
// register (including an exchange). P2-5c.
import 'dart:io';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/credit_note_slip.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

class FakePrinter implements LabelPrinter {
  final printed = <Uint8List>[];
  @override
  Future<void> printSheet(Uint8List pdf, {required String name}) async =>
      printed.add(pdf);
}

const managerPassword = 'a long passphrase';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late StockRepository stock;
  late SalesRepository sales;
  late ReturnsRepository returns;
  late ShiftRepository shifts;
  late SessionController session;
  late FakePrinter printer;
  late List<String> barcodes; // three M Blue at 499.00, one L Blue at 999.00
  late String cashierId;
  late String managerId;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    stock = StockRepository(db, newId: newId);
    sales = SalesRepository(db, newId: newId);
    returns = ReturnsRepository(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId);
    session = SessionController(auth: auth);
    printer = FakePrinter();
    await stock.ensureCounter();
    await stock.seedDefaultOptions();
    await stock.setShopName(role: Role.owner, name: 'Sample Apparel');
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
          PurchaseLine(
            size: 'L',
            color: 'Blue',
            quantity: 1,
            cost: Money(40000),
            mrp: Money(99900),
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
    await shifts.openShift(
      role: Role.cashier,
      userId: cashierId,
      counts: {Denomination.note500: 4},
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

  Future<void> open(
    WidgetTester tester, {
    String? as,
    String? secret,
    bool withShift = true,
  }) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(as ?? cashierId, secret ?? '482916');
      if (withShift &&
          await shifts.currentShift(session.user!.userId) == null) {
        await shifts.openShift(
          role: session.user!.role,
          userId: session.user!.userId,
          counts: {Denomination.note500: 4},
        );
      }
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: stock,
          sales: sales,
          returns: returns,
          shifts: shifts,
          auth: auth,
          printer: printer,
          fonts: () async => LabelFonts(
            regular: File('assets/fonts/NotoSans-Regular.ttf')
                .readAsBytesSync(),
            bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> goToReturns(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('returns-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // let the page slide in
    await pump(tester);
  }

  Future<void> scanReturn(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('return-barcode-field')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pump(tester);
  }

  Future<void> scanRegister(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('barcode-field')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pump(tester);
  }

  Future<void> sell(List<String> codes, {DateTime? at}) async {
    final repo = at == null
        ? sales
        : SalesRepository(db, newId: newId, now: () => at);
    final total = codes.fold<int>(
      0,
      (s, c) => s + (c == barcodes[3] ? 99900 : 49900),
    );
    await repo.saveBill(
      role: Role.manager,
      cashierId: cashierId,
      lines: [for (final c in codes) BillLineInput(c)],
      payments: [Payment(PaymentMode.cash, Money(total))],
    );
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  bool canComplete(WidgetTester tester, [String key = 'complete-return']) =>
      tester.widget<FilledButton>(find.byKey(Key(key))).onPressed != null;

  Future<String> statusOf(String code) async =>
      (await db
              .customSelect(
                'SELECT status FROM articles WHERE barcode_value = ?',
                variables: [Variable<String>(code)],
              )
              .getSingle())
          .read<String>('status');

  Future<void> chooseMode(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(Key('refund-mode-$name')));
    await tester.pump();
  }

  group('getting to the screen', () {
    testWidgets('a cashier has a Returns button', (tester) async {
      await open(tester);
      await goToReturns(tester);
      expect(find.byKey(const Key('return-barcode-field')), findsOneWidget);
    });
    testWidgets('a manager has a Returns button too', (tester) async {
      await open(tester, as: managerId, secret: managerPassword);
      await goToReturns(tester);
      expect(find.byKey(const Key('return-barcode-field')), findsOneWidget);
    });
  });

  group('scanning', () {
    testWidgets('a sold garment shows its bill and what was paid', (
      tester,
    ) async {
      await tester.runAsync(() => sell([barcodes[0]]));
      await open(tester);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      expect(find.byKey(Key('return-line-${barcodes[0]}')), findsOneWidget);
      expect(textOf(tester, 'refund-${barcodes[0]}'), '₹499.00');
      expect(textOf(tester, 'refund-total'), '₹499.00');
      expect(find.textContaining('Sold on bill 20'), findsOneWidget);
    });
    testWidgets(
      'unknown, never-sold, duplicate and already-returned barcodes say so',
      (tester) async {
        await tester.runAsync(() async {
          await sell([barcodes[0], barcodes[1]]);
          await returns.saveReturn(
            role: Role.cashier,
            cashierId: cashierId,
            items: [ReturnItemInput(barcodes[1], ReturnOutcome.restock)],
            refundMode: RefundMode.cash,
          );
        });
        await open(tester);
        await goToReturns(tester);
        await scanReturn(tester, '000000000000');
        expect(find.textContaining('Not found'), findsOneWidget);
        await scanReturn(tester, barcodes[2]);
        expect(find.textContaining('never sold'), findsOneWidget);
        await scanReturn(tester, barcodes[1]);
        expect(find.textContaining('already returned'), findsOneWidget);
        await scanReturn(tester, barcodes[0]);
        await scanReturn(tester, barcodes[0]);
        expect(find.textContaining('already in this return'), findsOneWidget);
        expect(textOf(tester, 'refund-total'), '₹499.00');
      },
    );
    testWidgets('a line can be removed', (tester) async {
      await tester.runAsync(() => sell([barcodes[0]]));
      await open(tester);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      await tester.tap(find.byKey(Key('return-remove-${barcodes[0]}')));
      await tester.pump();
      expect(find.byKey(Key('return-line-${barcodes[0]}')), findsNothing);
      expect(textOf(tester, 'refund-total'), '₹0.00');
    });
  });

  group('finishing a return', () {
    testWidgets('Complete stays off until a pay-out is chosen', (tester) async {
      await tester.runAsync(() => sell([barcodes[0]]));
      await open(tester);
      await goToReturns(tester);
      expect(canComplete(tester), isFalse);
      await scanReturn(tester, barcodes[0]);
      expect(canComplete(tester), isFalse);
      await chooseMode(tester, 'cash');
      expect(canComplete(tester), isTrue);
    });
    testWidgets('a cash return puts the garment back and says what to give', (
      tester,
    ) async {
      await tester.runAsync(() => sell([barcodes[0]]));
      await open(tester);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      await chooseMode(tester, 'cash');
      await tester.tap(find.byKey(const Key('complete-return')));
      await pump(tester);
      expect(textOf(tester, 'payout-text'), 'Give back ₹499.00 in cash.');
      expect(await tester.runAsync(() => statusOf(barcodes[0])), 'IN_STOCK');
    });
    testWidgets('UPI and card say how to refund', (tester) async {
      await tester.runAsync(() => sell([barcodes[0]]));
      await open(tester);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      await chooseMode(tester, 'upi');
      await tester.tap(find.byKey(const Key('complete-return')));
      await pump(tester);
      expect(textOf(tester, 'payout-text'), 'Send ₹499.00 back by UPI.');
    });
    testWidgets('a damaged garment needs a note, then is taken out of sale', (
      tester,
    ) async {
      await tester.runAsync(() => sell([barcodes[0]]));
      await open(tester);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      await chooseMode(tester, 'cash');
      await tester.tap(find.text('Damaged'));
      await tester.pump();
      expect(canComplete(tester), isFalse);
      await tester.enterText(
        find.byKey(Key('note-${barcodes[0]}')),
        'torn seam',
      );
      await tester.pump();
      expect(canComplete(tester), isTrue);
      await tester.tap(find.byKey(const Key('complete-return')));
      await pump(tester);
      expect(await tester.runAsync(() => statusOf(barcodes[0])), 'DAMAGED');
    });
    testWidgets('two garments refund their sum; New return starts empty', (
      tester,
    ) async {
      await tester.runAsync(() => sell([barcodes[0], barcodes[3]]));
      await open(tester);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      await scanReturn(tester, barcodes[3]);
      expect(textOf(tester, 'refund-total'), '₹1,498.00');
      await chooseMode(tester, 'cash');
      await tester.tap(find.byKey(const Key('complete-return')));
      await pump(tester);
      expect(textOf(tester, 'payout-text'), 'Give back ₹1,498.00 in cash.');
      await tester.tap(find.byKey(const Key('new-return')));
      await tester.pump();
      expect(find.byKey(const Key('return-lines')), findsNothing);
      expect(textOf(tester, 'refund-total'), '₹0.00');
    });
  });

  group('after 7 days', () {
    final long = DateTime.utc(2020, 1, 1, 6);
    testWidgets(
      'a cashier is told, asked for a manager, and a wrong password is refused',
      (tester) async {
        await tester.runAsync(() => sell([barcodes[0]], at: long));
        await open(tester);
        await goToReturns(tester);
        await scanReturn(tester, barcodes[0]);
        expect(find.byKey(Key('late-${barcodes[0]}')), findsOneWidget);
        await chooseMode(tester, 'cash');
        await tester.tap(find.byKey(const Key('complete-return')));
        await pump(tester);
        expect(find.byKey(const Key('approver-password')), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('approver-password')),
          'not it',
        );
        await tester.tap(find.byKey(const Key('approver-ok')));
        await pump(tester);
        expect(find.byKey(const Key('approval-error')), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await pump(tester);
        expect(await tester.runAsync(() => statusOf(barcodes[0])), 'SOLD');
      },
    );
    testWidgets(
      'the manager approves; it is saved under the cashier and recorded',
      (tester) async {
        await tester.runAsync(() => sell([barcodes[0]], at: long));
        await open(tester);
        await goToReturns(tester);
        await scanReturn(tester, barcodes[0]);
        await chooseMode(tester, 'cash');
        await tester.tap(find.byKey(const Key('complete-return')));
        await pump(tester);
        await tester.enterText(
          find.byKey(const Key('approver-password')),
          managerPassword,
        );
        await tester.tap(find.byKey(const Key('approver-ok')));
        await pump(tester);
        expect(find.byKey(const Key('return-saved-title')), findsOneWidget);
        final r = await tester.runAsync(
          () => db
              .customSelect('SELECT cashier_id, approved_by FROM returns')
              .getSingle(),
        );
        expect(r!.read<String>('cashier_id'), cashierId);
        expect(r.read<String>('approved_by'), managerId);
      },
    );
    testWidgets('a manager taking it themselves is not asked', (tester) async {
      await tester.runAsync(() => sell([barcodes[0]], at: long));
      await open(tester, as: managerId, secret: managerPassword);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      await chooseMode(tester, 'cash');
      await tester.tap(find.byKey(const Key('complete-return')));
      await pump(tester);
      expect(find.byKey(const Key('approver-password')), findsNothing);
      expect(find.byKey(const Key('return-saved-title')), findsOneWidget);
    });
  });

  group('credit notes', () {
    testWidgets(
      'a credit note refund shows the code and valid-till and prints a slip',
      (tester) async {
        await tester.runAsync(() => sell([barcodes[0]]));
        await open(tester);
        await goToReturns(tester);
        await scanReturn(tester, barcodes[0]);
        await chooseMode(tester, 'creditNote');
        await tester.tap(find.byKey(const Key('complete-return')));
        await pump(tester);
        expect(
          textOf(tester, 'payout-text'),
          'Credit note for ₹499.00 issued.',
        );
        expect(
          CreditNoteCode.tryParse(
            textOf(tester, 'note-code').replaceFirst('Code ', ''),
          ),
          isNotNull,
        );
        expect(textOf(tester, 'note-valid-till'), startsWith('Valid till '));
        await tester.runAsync(
          () => tester.tap(find.byKey(const Key('print-slip'))),
        );
        await pump(tester);
        expect(printer.printed.length, 1);
        expect(
          String.fromCharCodes(printer.printed.single.sublist(0, 5)),
          '%PDF-',
        );
      },
    );
    testWidgets(
      'only a credit note refund offers a slip; only exchange offers a new bill',
      (tester) async {
        await tester.runAsync(() => sell([barcodes[0]]));
        await open(tester);
        await goToReturns(tester);
        await scanReturn(tester, barcodes[0]);
        await chooseMode(tester, 'cash');
        await tester.tap(find.byKey(const Key('complete-return')));
        await pump(tester);
        expect(find.byKey(const Key('print-slip')), findsNothing);
        expect(find.byKey(const Key('start-exchange')), findsNothing);
      },
    );

    Future<String> noteFor(WidgetTester tester, List<String> sold) async {
      final saved = await tester.runAsync(() async {
        await sell(sold);
        return returns.saveReturn(
          role: Role.cashier,
          cashierId: cashierId,
          items: [
            for (final c in sold) ReturnItemInput(c, ReturnOutcome.restock),
          ],
          refundMode: RefundMode.creditNote,
        );
      });
      return saved!.creditNote!.code;
    }

    testWidgets(
      'exchange: the register opens with the note applied, a same-value garment is paid by it',
      (tester) async {
        await tester.runAsync(() => sell([barcodes[0]]));
        await open(tester);
        await goToReturns(tester);
        await scanReturn(tester, barcodes[0]);
        await chooseMode(tester, 'exchange');
        await tester.tap(find.byKey(const Key('complete-return')));
        await pump(tester);
        await tester.tap(find.byKey(const Key('start-exchange')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1)); // page slides in
        await pump(tester);
        final code = (await tester.runAsync(
          () => db.customSelect('SELECT code FROM credit_notes').getSingle(),
        ))!.read<String>('code');
        expect(find.byKey(Key('note-applied-$code')), findsOneWidget);
        await scanRegister(tester, barcodes[1]);
        expect(canComplete(tester, 'complete-bill'), isTrue);
        await tester.tap(find.byKey(const Key('complete-bill')));
        await pump(tester);
        expect(find.byKey(const Key('saved-title')), findsOneWidget);
        expect(find.byKey(const Key('saved-change')), findsNothing);
        expect(await tester.runAsync(() => statusOf(barcodes[1])), 'SOLD');
      },
    );
    testWidgets(
      'scanning a note at the register applies it; the rest is paid in cash',
      (tester) async {
        final code = await noteFor(tester, [barcodes[0]]); // 499.00 note
        await open(tester);
        await scanRegister(tester, barcodes[3]); // 999.00
        await scanRegister(tester, code);
        expect(find.byKey(Key('note-applied-$code')), findsOneWidget);
        expect(canComplete(tester, 'complete-bill'), isFalse);
        expect(textOf(tester, 'due-text'), 'Still due: ₹500.00');
        await tester.tap(find.byKey(const Key('exact-cash')));
        await tester.pump();
        expect(canComplete(tester, 'complete-bill'), isTrue);
        await tester.tap(find.byKey(const Key('complete-bill')));
        await pump(tester);
        expect(find.byKey(const Key('saved-title')), findsOneWidget);
        final info = await tester.runAsync(
          () => sales.lookupCreditNote(role: Role.cashier, code: code),
        );
        expect(info!.balance, Money.zero);
      },
    );
    testWidgets('a bigger note pays the whole bill and the rest stays on it', (
      tester,
    ) async {
      final code = await noteFor(tester, [barcodes[3]]); // 999.00 note
      await open(tester);
      await scanRegister(tester, barcodes[1]); // 499.00
      await scanRegister(tester, code);
      expect(find.textContaining('stays on it'), findsOneWidget);
      expect(canComplete(tester, 'complete-bill'), isTrue);
      await tester.tap(find.byKey(const Key('complete-bill')));
      await pump(tester);
      final info = await tester.runAsync(
        () => sales.lookupCreditNote(role: Role.cashier, code: code),
      );
      expect(info!.balance, Money(50000));
    });
    testWidgets('an unknown note, a repeated note and an empty note say so', (
      tester,
    ) async {
      final code = await noteFor(tester, [barcodes[0]]);
      await open(tester);
      await scanRegister(
        tester,
        CreditNoteCode(counterNo: 1, serial: 9999).value,
      );
      expect(find.textContaining('Credit note not found'), findsOneWidget);
      await scanRegister(tester, barcodes[1]);
      await scanRegister(tester, code);
      await scanRegister(tester, code);
      expect(find.textContaining('already on this bill'), findsWidgets);
      await tester.tap(find.byKey(const Key('complete-bill')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('new-bill')));
      await tester.pump();
      await scanRegister(tester, barcodes[2]);
      await scanRegister(tester, code);
      expect(find.textContaining('nothing left'), findsOneWidget);
    });
    testWidgets('a note can be taken off the bill again', (tester) async {
      final code = await noteFor(tester, [barcodes[0]]);
      await open(tester);
      await scanRegister(tester, barcodes[1]);
      await scanRegister(tester, code);
      await tester.tap(find.byKey(Key('note-remove-$code')));
      await tester.pump();
      expect(find.byKey(Key('note-applied-$code')), findsNothing);
      expect(canComplete(tester, 'complete-bill'), isFalse);
    });
  });

  group('the slip text', () {
    final note = IssuedCreditNote(
      id: 'n1',
      code: CreditNoteCode(counterNo: 1, serial: 12).value,
      amount: Money(149800),
      issuedAt: DateTime.utc(2026, 11, 20, 10),
      lastDay: DateTime.utc(2027, 5, 19),
    );
    test('says amount, code, note number, issue time and valid-till', () {
      final s = describeSlip(note: note, shopName: 'Sample Apparel');
      expect(s.shopName, 'Sample Apparel');
      expect(s.amountText, '₹1,498.00');
      expect(s.code, note.code);
      expect(s.noteNumber, 'C1-00012');
      expect(s.issuedText, '20-11-2026 15:30');
      expect(s.validTillText, '19-05-2027');
    });
    test('a code that is not a credit note is refused', () {
      expect(
        () => describeSlip(
          note: IssuedCreditNote(
            id: 'x',
            code: '261100000007',
            amount: Money(100),
            issuedAt: DateTime.utc(2026),
            lastDay: DateTime.utc(2027),
          ),
          shopName: null,
        ),
        throwsArgumentError,
      );
    });
    test('builds a one-page PDF', () async {
      final fonts = LabelFonts(
        regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
        bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
      );
      final bytes = await buildCreditNoteSlipPdf(
        describeSlip(note: note, shopName: null),
        fonts,
      );
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('locking', () {
    testWidgets('locking closes the returns screen and forgets the return', (
      tester,
    ) async {
      await tester.runAsync(() => sell([barcodes[0]]));
      await open(tester);
      await goToReturns(tester);
      await scanReturn(tester, barcodes[0]);
      session.lock();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // page slides out
      expect(find.byKey(const Key('return-barcode-field')), findsNothing);
      expect(await tester.runAsync(() => statusOf(barcodes[0])), 'SOLD');
    });
  });
}
