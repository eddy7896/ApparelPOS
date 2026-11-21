// The backup screens: where backups go, status and failures for the manager,
// Back up now, the Restore screen with its guards, the first-launch restore, and
// the automatic backup after a shift close. P3-2c.
import 'dart:io';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/pickers.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/backup/backup_models.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';
import 'package:pos_windows/app/ui/backup_screen.dart';

import '../support/fake_backup_controller.dart';

const managerPassword = 'a long passphrase';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late ShiftRepository shifts;
  late SessionController session;
  late FakeBackupController fake;
  late String cashierId;
  late String managerId;
  var chosenFolder = '/mnt/usb/Backups';
  String? chosenFile = '/mnt/usb/Backups/apparel-pos-20261121-153000.backup';
  var n = 0;
  String newId() => 'id-${++n}';
  // "now" on the counter: 21 Nov 2026, 15:30 India
  final clock = DateTime.utc(2026, 11, 21, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    shifts = ShiftRepository(db, newId: newId, now: () => clock);
    session = SessionController(auth: auth, now: () => clock);
    fake = FakeBackupController();
    chosenFolder = '/mnt/usb/Backups';
    chosenFile = '/mnt/usb/Backups/apparel-pos-20261121-153000.backup';
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

  AppServices services({BackupController? backup, bool preview = false}) =>
      AppServices(
        stock: StockRepository(db, newId: newId),
        sales: SalesRepository(db, newId: newId),
        returns: ReturnsRepository(db, newId: newId),
        shifts: shifts,
        reports: ReportRepository(db),
        auth: auth,
        backup: preview ? null : (backup ?? fake),
        pickers: FilePickers(
          folder: () async => chosenFolder,
          backupFile: () async => chosenFile,
        ),
        printer: const SystemLabelPrinter(),
        fonts: () async => LabelFonts(
          regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
          bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
        ),
      );

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

  Future<void> openApp(
    WidgetTester tester, {
    bool manager = true,
    AppServices? svc,
    bool signIn = true,
  }) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await session.start();
      if (signIn) {
        await session.signIn(
          manager ? managerId : cashierId,
          manager ? managerPassword : '482916',
        );
      }
    });
    await tester.pumpWidget(
      PosApp(session: session, services: svc ?? services()),
    );
    await pump(tester);
  }

  Future<void> goTo(WidgetTester tester, String buttonKey) async {
    await tester.tap(find.byKey(Key(buttonKey)));
    await slide(tester);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  group('getting to Backups', () {
    testWidgets('a manager has a Backups button; a cashier does not', (
      tester,
    ) async {
      await openApp(tester, manager: false);
      expect(find.byKey(const Key('backups-button')), findsNothing);
      expect(find.byKey(const Key('backup-banner')), findsNothing);
    });
    testWidgets('in the browser preview the screen says there are no backups', (
      tester,
    ) async {
      await openApp(tester, svc: services(preview: true));
      await goTo(tester, 'backups-button');
      expect(find.byKey(const Key('no-backup')), findsOneWidget);
      expect(find.byKey(const Key('backup-banner')), findsNothing);
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
          home: BackupScreen(session: session, services: services()),
        ),
      );
      await pump(tester);
      expect(find.byKey(const Key('backup-error')), findsOneWidget);
    });
  });

  group('choosing places and backing up', () {
    testWidgets('both places start empty and Back up now is off', (
      tester,
    ) async {
      await openApp(tester);
      await goTo(tester, 'backups-button');
      expect(textOf(tester, 'place-1'), 'Not chosen');
      expect(textOf(tester, 'place-2'), 'Not chosen');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('backup-now')))
            .onPressed,
        isNull,
      );
      expect(textOf(tester, 'last-complete'), 'No complete backup yet.');
    });
    testWidgets(
      'a folder is chosen with the dialog, shown, and can be cleared',
      (tester) async {
        await openApp(tester);
        await goTo(tester, 'backups-button');
        await tester.tap(find.byKey(const Key('choose-place-1')));
        await pump(tester);
        expect(textOf(tester, 'place-1'), '/mnt/usb/Backups');
        expect(fake.calls, contains('setPlace 1 /mnt/usb/Backups'));
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('backup-now')))
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byKey(const Key('clear-place-1')));
        await pump(tester);
        expect(textOf(tester, 'place-1'), 'Not chosen');
      },
    );
    testWidgets('cancelling the dialog changes nothing', (tester) async {
      final svc = AppServices(
        stock: StockRepository(db, newId: newId),
        sales: SalesRepository(db, newId: newId),
        returns: ReturnsRepository(db, newId: newId),
        shifts: shifts,
        reports: ReportRepository(db),
        auth: auth,
        backup: fake,
        pickers: FilePickers(folder: () async => null),
        printer: const SystemLabelPrinter(),
        fonts: () async => throw StateError('x'),
      );
      await openApp(tester, svc: svc);
      await goTo(tester, 'backups-button');
      await tester.tap(find.byKey(const Key('choose-place-2')));
      await pump(tester);
      expect(textOf(tester, 'place-2'), 'Not chosen');
      expect(fake.calls, isEmpty);
    });
    testWidgets('Back up now reports how many places got a copy', (
      tester,
    ) async {
      fake.places = {1: '/usb', 2: '/folder'};
      await openApp(tester);
      await goTo(tester, 'backups-button');
      await tester.tap(find.byKey(const Key('backup-now')));
      await pump(tester);
      expect(textOf(tester, 'backup-result'), 'Backed up to 2 of 2 places.');
      expect(
        textOf(tester, 'last-complete'),
        startsWith('Last complete backup: 21-11-2026'),
      );
    });
    testWidgets('a place that failed is named with the reason', (tester) async {
      fake.places = {1: '/usb', 2: '/folder'};
      fake.nextResult = BackupResult(
        at: clock,
        places: const [
          PlaceResult(slot: 1, ok: true, fileName: 'x'),
          PlaceResult(
            slot: 2,
            ok: false,
            error: 'the folder is not there (is the drive plugged in?)',
          ),
        ],
      );
      fake.failures = {2: 'the folder is not there (is the drive plugged in?)'};
      await openApp(tester);
      await goTo(tester, 'backups-button');
      await tester.tap(find.byKey(const Key('backup-now')));
      await pump(tester);
      expect(
        textOf(tester, 'backup-result'),
        contains('Backed up to 1 of 2 places.'),
      );
      expect(
        textOf(tester, 'backup-result'),
        contains('Second folder: the folder is not there'),
      );
      expect(
        textOf(tester, 'failure-2'),
        contains('Second folder failed last time'),
      );
    });
  });

  group('the banner on the manager home screen', () {
    testWidgets('says when backups are not set up', (tester) async {
      await openApp(tester);
      expect(textOf(tester, 'backup-warning'), contains('not set up'));
    });
    testWidgets('says which place failed', (tester) async {
      fake.places = {1: '/usb', 2: '/folder'};
      fake.failures = {1: 'gone'};
      fake.lastComplete = clock;
      await openApp(tester);
      expect(textOf(tester, 'backup-warning'), contains('USB drive'));
    });
    testWidgets('says when no complete backup was made today', (tester) async {
      fake.places = {1: '/usb', 2: null};
      fake.lastComplete = DateTime.utc(2026, 11, 20, 4);
      await openApp(tester);
      expect(textOf(tester, 'backup-warning'), 'No complete backup yet today.');
    });
    testWidgets('is calm when a complete backup was made today', (
      tester,
    ) async {
      fake.places = {1: '/usb', 2: null};
      fake.lastComplete = DateTime.utc(2026, 11, 21, 4);
      await openApp(tester);
      expect(find.byKey(const Key('backup-warning')), findsNothing);
      expect(
        textOf(tester, 'backup-ok'),
        startsWith('Last complete backup: 21-11-2026'),
      );
    });
    testWidgets('tapping it opens the Backups screen', (tester) async {
      await openApp(tester);
      await goTo(tester, 'backup-banner');
      expect(find.byKey(const Key('choose-place-1')), findsOneWidget);
    });
  });

  group('restoring in Manager Mode', () {
    Future<void> toRestore(WidgetTester tester) async {
      fake.places = {1: '/usb', 2: null};
      await openApp(tester);
      await goTo(tester, 'backups-button');
      await goTo(tester, 'open-restore');
    }

    bool goEnabled(WidgetTester tester) =>
        tester
            .widget<FilledButton>(find.byKey(const Key('restore-go')))
            .onPressed !=
        null;

    testWidgets(
      'Restore stays off until a file is chosen and RESTORE is typed exactly',
      (tester) async {
        await toRestore(tester);
        expect(goEnabled(tester), isFalse);
        await tester.enterText(
          find.byKey(const Key('restore-confirm')),
          'RESTORE',
        );
        await tester.pump();
        expect(goEnabled(tester), isFalse); // no file yet
        await tester.tap(find.byKey(const Key('choose-backup-file')));
        await pump(tester);
        expect(textOf(tester, 'backup-file-name'), chosenFile);
        expect(goEnabled(tester), isTrue);
        await tester.enterText(
          find.byKey(const Key('restore-confirm')),
          'restore',
        );
        await tester.pump();
        expect(goEnabled(tester), isFalse);
        await tester.enterText(
          find.byKey(const Key('restore-confirm')),
          'RESTORE ',
        );
        await tester.pump();
        expect(goEnabled(tester), isFalse);
      },
    );

    Future<void> ready(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('choose-backup-file')));
      await pump(tester);
      await tester.enterText(
        find.byKey(const Key('restore-confirm')),
        'RESTORE',
      );
      await tester.enterText(
        find.byKey(const Key('restore-recovery-key')),
        'AAAA-BBBB',
      );
      await tester.pump();
    }

    testWidgets(
      'asks for the owner\'s password again; a wrong one restores nothing',
      (tester) async {
        await toRestore(tester);
        await ready(tester);
        await tester.tap(find.byKey(const Key('restore-go')));
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
        expect(fake.calls, isNot(contains('restore')));
      },
    );

    testWidgets(
      'with the right password it restores, then says Restore finished and closes the app',
      (tester) async {
        await toRestore(tester);
        await ready(tester);
        await tester.tap(find.byKey(const Key('restore-go')));
        await pump(tester);
        await tester.enterText(
          find.byKey(const Key('approver-password')),
          managerPassword,
        );
        await tester.tap(find.byKey(const Key('approver-ok')));
        await pump(tester);
        expect(fake.restoredPath, chosenFile);
        expect(fake.restoredKeyText, 'AAAA-BBBB');
        expect(fake.restoredFirstRun, isFalse);
        expect(textOf(tester, 'restore-done-title'), 'Restore finished');
        await tester.tap(find.byKey(const Key('restore-close')));
        await pump(tester);
        expect(fake.quits, 1);
      },
    );

    for (final (outcome, expected) in [
      (RestoreOutcome.wrongKey, 'does not open this backup'),
      (RestoreOutcome.badRecoveryKey, 'recovery key is not right'),
      (RestoreOutcome.damaged, 'not a healthy backup'),
      (RestoreOutcome.tooNew, 'newer version'),
      (RestoreOutcome.keyMismatch, 'different key'),
      (RestoreOutcome.keyRequired, 'Type in the recovery key'),
    ]) {
      testWidgets(
        'a mistake (${outcome.name}) is explained and nothing closes',
        (tester) async {
          fake.nextRestore = RestoreReport(outcome);
          await toRestore(tester);
          await ready(tester);
          await tester.tap(find.byKey(const Key('restore-go')));
          await pump(tester);
          await tester.enterText(
            find.byKey(const Key('approver-password')),
            managerPassword,
          );
          await tester.tap(find.byKey(const Key('approver-ok')));
          await pump(tester);
          expect(textOf(tester, 'restore-message'), contains(expected));
          expect(find.byKey(const Key('restore-close')), findsNothing);
          expect(find.byKey(const Key('restore-go')), findsOneWidget);
        },
      );
    }

    testWidgets(
      'a restore that stopped after closing the data still asks to close the app',
      (tester) async {
        fake.nextRestore = const RestoreReport(
          RestoreOutcome.failed,
          needsRestart: true,
        );
        await toRestore(tester);
        await ready(tester);
        await tester.tap(find.byKey(const Key('restore-go')));
        await pump(tester);
        await tester.enterText(
          find.byKey(const Key('approver-password')),
          managerPassword,
        );
        await tester.tap(find.byKey(const Key('approver-ok')));
        await pump(tester);
        expect(textOf(tester, 'restore-done-title'), 'The restore stopped');
        expect(find.byKey(const Key('restore-close')), findsOneWidget);
      },
    );

    testWidgets(
      'after a restore the kept-aside data can be deleted, after a confirmation',
      (tester) async {
        fake.places = {1: '/usb', 2: null};
        fake.asideCopies = 1;
        await openApp(tester);
        await goTo(tester, 'backups-button');
        expect(find.byKey(const Key('aside-note')), findsOneWidget);
        await tester.tap(find.byKey(const Key('discard-aside')));
        await pump(tester);
        await tester.tap(find.text('Keep it'));
        await pump(tester);
        expect(fake.calls, isNot(contains('discard')));
        await tester.tap(find.byKey(const Key('discard-aside')));
        await pump(tester);
        await tester.tap(find.byKey(const Key('confirm-discard')));
        await pump(tester);
        expect(fake.calls, contains('discard'));
        expect(find.byKey(const Key('aside-note')), findsNothing);
      },
    );
  });

  group('the first launch on a new computer', () {
    testWidgets(
      'the set-up screen offers a restore only when backups exist here',
      (tester) async {
        await tester.runAsync(() async {
          await db.customStatement('DELETE FROM users');
        });
        await openApp(tester, signIn: false, svc: services(preview: true));
        expect(find.byKey(const Key('setup-restore')), findsNothing);
      },
    );

    testWidgets('restores with no password, as a first run, then closes', (
      tester,
    ) async {
      await tester.runAsync(
        () async => db.customStatement('DELETE FROM users'),
      );
      await openApp(tester, signIn: false);
      expect(find.byKey(const Key('setup-restore')), findsOneWidget);
      await tester.tap(find.byKey(const Key('setup-restore')));
      await slide(tester);
      await tester.tap(find.byKey(const Key('choose-backup-file')));
      await pump(tester);
      await tester.enterText(
        find.byKey(const Key('restore-recovery-key')),
        'AAAA-BBBB',
      );
      await tester.enterText(
        find.byKey(const Key('restore-confirm')),
        'RESTORE',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('restore-go')));
      await pump(tester);
      expect(find.byKey(const Key('approver-password')), findsNothing);
      expect(fake.restoredFirstRun, isTrue);
      expect(textOf(tester, 'restore-done-title'), 'Restore finished');
    });
  });

  group('the automatic backup after a shift close', () {
    Future<void> closeOwnShift(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('close-shift-button')));
      await slide(tester);
      await tester.tap(find.byKey(const Key('count-submit')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('confirm-close')));
      await pump(tester);
    }

    testWidgets('runs when the last open shift is closed', (tester) async {
      await tester.runAsync(
        () => shifts.openShift(
          role: Role.cashier,
          userId: cashierId,
          counts: const {},
        ),
      );
      await openApp(tester, manager: false);
      await closeOwnShift(tester);
      expect(fake.afterCloseOpenLeft, 0);
      expect(find.byKey(const Key('shift-closed-title')), findsOneWidget);
    });

    testWidgets('is told another shift is still open', (tester) async {
      await tester.runAsync(() async {
        await shifts.openShift(
          role: Role.cashier,
          userId: cashierId,
          counts: const {},
        );
        await shifts.openShift(
          role: Role.manager,
          userId: managerId,
          counts: const {},
        );
      });
      await openApp(tester, manager: false);
      await closeOwnShift(tester);
      expect(fake.afterCloseOpenLeft, 1);
    });

    testWidgets('also runs when an earlier day\'s shift is closed at sign-in', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await ShiftRepository(
          db,
          newId: newId,
          now: () => DateTime.utc(2020, 1, 1, 6),
        ).openShift(role: Role.cashier, userId: cashierId, counts: const {});
      });
      await openApp(tester, manager: false);
      await tester.tap(find.byKey(const Key('count-submit')));
      await pump(tester);
      expect(fake.afterCloseOpenLeft, 0);
    });

    testWidgets(
      'a shift close still works with no backup controller (the preview)',
      (tester) async {
        await tester.runAsync(
          () => shifts.openShift(
            role: Role.cashier,
            userId: cashierId,
            counts: const {},
          ),
        );
        await openApp(tester, manager: false, svc: services(preview: true));
        await closeOwnShift(tester);
        expect(find.byKey(const Key('shift-closed-title')), findsOneWidget);
      },
    );
  });
}
