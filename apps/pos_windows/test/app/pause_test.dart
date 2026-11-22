// UX-3: the shift opens in a popup at sign-in, the top bar has Pause, Close
// shift and Lock, Pause locks the counter and keeps the shift open, and
// signing back in carries on. Owner decisions 2026-11-22.
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
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late ShiftRepository shifts;
  late SessionController session;
  late String ashaId;
  late String raviId;
  late String barcode;
  late String managerId;
  late DateTime clock;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    final stock = StockRepository(db, newId: newId);
    clock = DateTime.now().toUtc();
    shifts = ShiftRepository(db, newId: newId, now: () => clock);
    session = SessionController(auth: auth);
    await stock.ensureCounter();
    ashaId = await auth.createUser(
      name: 'Asha',
      role: Role.cashier,
      secret: '482916',
    );
    raviId = await auth.createUser(
      name: 'Ravi',
      role: Role.cashier,
      secret: '135792',
    );
    managerId = await auth.createUser(
      name: 'Meera',
      role: Role.manager,
      secret: 'a long passphrase',
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
            quantity: 1,
            cost: Money(20000),
            mrp: Money(49900),
          ),
        ],
      ),
    );
    barcode =
        (await db
                .customSelect(
                  'SELECT barcode_value FROM articles WHERE batch_id = ?',
                  variables: [Variable<String>(r.batchId)],
                )
                .getSingle())
            .read<String>('barcode_value');
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

  Future<void> start(
    WidgetTester tester, {
    String? signInAs,
    String? pin,
  }) async {
    tester.view.physicalSize = const Size(1500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      if (signInAs != null) {
        await session.signIn(signInAs, pin!);
      }
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: StockRepository(db, newId: newId),
          sales: SalesRepository(db, newId: newId),
          returns: ReturnsRepository(db, newId: newId),
          shifts: shifts,
          reports: ReportRepository(db),
          auth: auth,
          printer: const SystemLabelPrinter(),
          fonts: () async => LabelFonts(
            regular: File('assets/fonts/NotoSans-Regular.ttf')
                .readAsBytesSync(),
            bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
          ),
        ),
      ),
    );
    await pump(tester);
  }

  Future<void> openShift(String id) =>
      shifts.openShift(role: Role.cashier, userId: id, counts: const {});

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('c');

  bool enabled(WidgetTester tester, String key) =>
      tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed != null;

  testWidgets('the shift opens in a popup over a dimmed counter', (
    tester,
  ) async {
    await start(tester, signInAs: ashaId, pin: '482916');
    expect(find.byKey(const Key('shift-popup')), findsOneWidget);
    expect(find.byKey(const Key('open-shift-title')), findsOneWidget);
    expect(find.byKey(const Key('barcode-field')), findsNothing);
  });

  testWidgets('the top bar has Pause, Close shift and Lock', (tester) async {
    await tester.runAsync(() => openShift(ashaId));
    await start(tester, signInAs: ashaId, pin: '482916');
    expect(find.byKey(const Key('pause-button')), findsOneWidget);
    expect(find.byKey(const Key('close-shift-button')), findsOneWidget);
    expect(find.byKey(const Key('lock-button')), findsOneWidget);
    expect(enabled(tester, 'pause-button'), isTrue);
    expect(enabled(tester, 'close-shift-button'), isTrue);
  });

  testWidgets('Pause and Close shift wait while a bill is in progress', (
    tester,
  ) async {
    await tester.runAsync(() => openShift(ashaId));
    await start(tester, signInAs: ashaId, pin: '482916');
    await tester.enterText(find.byKey(const Key('barcode-field')), barcode);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pump(tester);
    await tester.pump();
    expect(enabled(tester, 'pause-button'), isFalse);
    expect(enabled(tester, 'close-shift-button'), isFalse);
    expect(enabled(tester, 'lock-button'), isTrue);
  });

  testWidgets('Pause locks the counter, says who is on a break, keeps the '
      'shift open and records the break', (tester) async {
    await tester.runAsync(() => openShift(ashaId));
    await start(tester, signInAs: ashaId, pin: '482916');
    await tester.tap(find.byKey(const Key('pause-button')));
    await pump(tester);
    expect(session.stage, SessionStage.locked);
    expect(find.byKey(const Key('on-break-banner')), findsOneWidget);
    expect(find.textContaining('Asha is on a break'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => count(
          'SELECT COUNT(*) AS c FROM shifts s WHERE NOT EXISTS '
          '(SELECT 1 FROM shift_closes c WHERE c.shift_id = s.id)',
        ),
      ),
      1,
    );
    expect(
      await tester.runAsync(
        () => count('SELECT COUNT(*) AS c FROM shift_breaks'),
      ),
      1,
    );
    expect(
      await tester.runAsync(
        () => count('SELECT COUNT(*) AS c FROM shift_break_ends'),
      ),
      0,
    );
  });

  testWidgets('a plain Lock is not a break', (tester) async {
    await tester.runAsync(() => openShift(ashaId));
    await start(tester, signInAs: ashaId, pin: '482916');
    await tester.tap(find.byKey(const Key('lock-button')));
    await pump(tester);
    expect(session.stage, SessionStage.locked);
    expect(find.byKey(const Key('on-break-banner')), findsNothing);
    expect(
      await tester.runAsync(
        () => count('SELECT COUNT(*) AS c FROM shift_breaks'),
      ),
      0,
    );
  });

  testWidgets('signing back in ends the break and shows the register, with no '
      'drawer count', (tester) async {
    await tester.runAsync(() => openShift(ashaId));
    await start(tester, signInAs: ashaId, pin: '482916');
    await tester.tap(find.byKey(const Key('pause-button')));
    await pump(tester);
    await tester.runAsync(() => session.signIn(ashaId, '482916'));
    await pump(tester);
    expect(find.byKey(const Key('barcode-field')), findsOneWidget);
    expect(find.byKey(const Key('shift-popup')), findsNothing);
    expect(find.byKey(const Key('on-break-banner')), findsNothing);
    expect(
      await tester.runAsync(
        () => count('SELECT COUNT(*) AS c FROM shift_break_ends'),
      ),
      1,
    );
  });

  testWidgets('a later plain Lock does not claim a break', (tester) async {
    await tester.runAsync(() => openShift(ashaId));
    await start(tester, signInAs: ashaId, pin: '482916');
    await tester.tap(find.byKey(const Key('pause-button')));
    await pump(tester);
    await tester.runAsync(() => session.signIn(ashaId, '482916'));
    await pump(tester);
    await tester.tap(find.byKey(const Key('lock-button')));
    await pump(tester);
    expect(session.stage, SessionStage.locked);
    expect(find.byKey(const Key('on-break-banner')), findsNothing);
  });

  testWidgets('another cashier cannot open a shift while the drawer is on a '
      'break', (tester) async {
    await tester.runAsync(() => openShift(ashaId));
    await start(tester, signInAs: ashaId, pin: '482916');
    await tester.tap(find.byKey(const Key('pause-button')));
    await pump(tester);
    await tester.runAsync(() => session.signIn(raviId, '135792'));
    await pump(tester);
    expect(find.byKey(const Key('shift-popup')), findsOneWidget);
    await tester.tap(find.byKey(const Key('count-submit')));
    await pump(tester);
    expect(find.textContaining('The drawer is on a break'), findsOneWidget);
    expect(find.byKey(const Key('barcode-field')), findsNothing);
    expect(
      await tester.runAsync(() => count('SELECT COUNT(*) AS c FROM shifts')),
      1,
    );
  });

  testWidgets('the owner sees the break time in the list of closes', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await openShift(ashaId);
      await shifts.pauseShift(role: Role.cashier, userId: ashaId);
      clock = clock.add(const Duration(minutes: 12));
      await shifts.resumeShift(role: Role.cashier, userId: ashaId);
      await shifts.closeShift(
        role: Role.cashier,
        userId: ashaId,
        counts: const {},
      );
    });
    await start(tester, signInAs: managerId, pin: 'a long passphrase');
    await tester.tap(find.byKey(const Key('shift-closes-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await pump(tester);
    expect(find.text('Breaks 12 min'), findsOneWidget);
  });
}
