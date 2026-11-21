// The recovery key screen: shown to the owner or manager until they type the
// last group back; never to a cashier; once only. P3-1.
import 'dart:io';
import 'dart:math';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/encryption/encrypted_connection.dart';
import 'package:pos_windows/data/encryption/key_store.dart';
import 'package:pos_windows/data/recovery_key_repository.dart';
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
  late SessionController session;
  late MemoryKeyStore keys;
  late RecoveryKeyRepository recovery;
  late String cashierId;
  late String managerId;
  late String text;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    session = SessionController(auth: auth);
    keys = MemoryKeyStore(newDatabaseKey(Random(11)));
    recovery = RecoveryKeyRepository(db, keys, newId: newId);
    text = RecoveryKey.format((await keys.read())!);
    await StockRepository(db, newId: newId).ensureCounter();
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
    bool manager = true,
    bool withRecovery = true,
  }) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      await session.signIn(
        manager ? managerId : cashierId,
        manager ? managerPassword : '482916',
      );
    });
    await tester.pumpWidget(
      PosApp(
        session: session,
        services: AppServices(
          stock: StockRepository(db, newId: newId),
          sales: SalesRepository(db, newId: newId),
          returns: ReturnsRepository(db, newId: newId),
          shifts: ShiftRepository(db, newId: newId),
          reports: ReportRepository(db),
          auth: auth,
          recovery: withRecovery ? recovery : null,
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

  testWidgets('a manager first sees the recovery key, and not Manager Mode', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('recovery-title')), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(find.byKey(const Key('recovery-key-text')))
          .data,
      text,
    );
    expect(find.byKey(const Key('stock-entry-button')), findsNothing);
  });

  testWidgets('Continue stays off until the last group is typed right', (
    tester,
  ) async {
    await open(tester);
    bool enabled() =>
        tester
            .widget<FilledButton>(find.byKey(const Key('recovery-continue')))
            .onPressed !=
        null;
    expect(enabled(), isFalse);
    await tester.enterText(
      find.byKey(const Key('recovery-check-field')),
      'ZZZZ',
    );
    await tester.pump();
    expect(enabled(), isFalse);
    await tester.enterText(
      find.byKey(const Key('recovery-check-field')),
      text.split('-').first,
    );
    await tester.pump();
    expect(enabled(), isFalse); // the first group is not the last one
    await tester.enterText(
      find.byKey(const Key('recovery-check-field')),
      ' ${text.split('-').last.toLowerCase()} ',
    );
    await tester.pump();
    expect(enabled(), isTrue);
  });

  testWidgets(
    'after Continue, Manager Mode shows and the key is gone from the screen',
    (tester) async {
      await open(tester);
      await tester.enterText(
        find.byKey(const Key('recovery-check-field')),
        text.split('-').last,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('recovery-continue')));
      await pump(tester);
      expect(find.byKey(const Key('stock-entry-button')), findsOneWidget);
      expect(find.byKey(const Key('recovery-key-text')), findsNothing);
      expect(find.textContaining(text), findsNothing);
      expect(await tester.runAsync(recovery.needsAcknowledgement), isFalse);
    },
  );

  testWidgets(
    'it is shown once: the next sign-in goes straight to Manager Mode',
    (tester) async {
      await tester.runAsync(
        () => recovery.acknowledge(role: Role.owner, userId: managerId),
      );
      await open(tester);
      expect(find.byKey(const Key('recovery-title')), findsNothing);
      expect(find.byKey(const Key('stock-entry-button')), findsOneWidget);
    },
  );

  testWidgets('it is still asked for if the app was closed before Continue', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('recovery-title')), findsOneWidget);
    session.lock();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => session.signIn(managerId, managerPassword));
    await pump(tester);
    expect(find.byKey(const Key('recovery-title')), findsOneWidget);
  });

  testWidgets(
    'a cashier never sees it, and it is still waiting for the owner',
    (tester) async {
      await open(tester, manager: false);
      expect(find.byKey(const Key('recovery-title')), findsNothing);
      expect(find.byKey(const Key('recovery-key-text')), findsNothing);
      expect(await tester.runAsync(recovery.needsAcknowledgement), isTrue);
    },
  );

  testWidgets(
    'with no key store (the browser preview) Manager Mode shows at once',
    (tester) async {
      await open(tester, withRecovery: false);
      expect(find.byKey(const Key('recovery-title')), findsNothing);
      expect(find.byKey(const Key('stock-entry-button')), findsOneWidget);
    },
  );
}
