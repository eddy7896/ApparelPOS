// The shop's name, color and logo on screen come from settings, not code: the
// placeholder look, a saved look, the theme, the mark, the PDFs, and the
// development-only preview. UX-1.
import 'dart:io';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/app/app.dart';
import 'package:pos_windows/app/bill_pdf.dart';
import 'package:pos_windows/app/brand_controller.dart';
import 'package:pos_windows/app/credit_note_slip.dart';
import 'package:pos_windows/app/label_printer.dart';
import 'package:pos_windows/app/pickers.dart';
import 'package:pos_windows/app/services.dart';
import 'package:pos_windows/app/session_controller.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/auth_service.dart';
import 'package:pos_windows/data/brand_repository.dart';
import 'package:pos_windows/data/report_repository.dart';
import 'package:pos_windows/data/returns_repository.dart';
import 'package:pos_windows/data/sales_repository.dart';
import 'package:pos_windows/data/shift_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

import '../support/fake_backup_controller.dart';
import '../support/png.dart';

const managerPassword = 'a long passphrase';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late AuthService auth;
  late SessionController session;
  late BrandRepository repo;
  late BrandController brand;
  late String cashierId;
  late String managerId;
  Uint8List? pickedLogo;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    auth = AuthService(db, newId: newId);
    session = SessionController(auth: auth);
    repo = BrandRepository(db, newId: newId);
    brand = BrandController(repo);
    pickedLogo = null;
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

  AppServices services({
    bool preview = false,
    bool withBrand = true,
    bool withBackup = false,
  }) => AppServices(
    stock: StockRepository(db, newId: newId),
    sales: SalesRepository(db, newId: newId),
    returns: ReturnsRepository(db, newId: newId),
    shifts: ShiftRepository(db, newId: newId),
    reports: ReportRepository(db),
    auth: auth,
    brand: withBrand ? brand : null,
    backup: withBackup ? FakeBackupController() : null,
    brandPreview: preview,
    pickers: FilePickers(logoFile: () async => pickedLogo),
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
    // a theme change animates for 200 ms: let it finish
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openApp(
    WidgetTester tester, {
    bool signIn = false,
    bool manager = true,
    AppServices? svc,
  }) async {
    tester.view.physicalSize = const Size(1400, 1600);
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
      await brand.reload();
    });
    await tester.pumpWidget(
      PosApp(session: session, services: svc ?? services()),
    );
    await pump(tester);
  }

  Color primary(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.primary;

  String nameShown(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('brand-name')).first).data!;

  group('before the owner sets anything (the placeholder)', () {
    testWidgets(
      'the sign-in screen shows the placeholder name and a letter mark, not a product name',
      (tester) async {
        await openApp(tester);
        expect(nameShown(tester), 'Your Shop');
        expect(find.byKey(const Key('brand-initial')), findsOneWidget);
        expect(find.text('Y'), findsOneWidget);
        expect(find.byKey(const Key('brand-logo')), findsNothing);
        expect(find.text('Apparel PoS'), findsNothing);
      },
    );
    testWidgets('the theme uses the placeholder color', (tester) async {
      await openApp(tester);
      expect(primary(tester).toARGB32() & 0xFFFFFF, 0x2B3A9F);
    });
  });

  group('a saved look', () {
    testWidgets(
      'name, logo and color show on the sign-in screen and in the theme, at once',
      (tester) async {
        await openApp(tester);
        await tester.runAsync(
          () => brand.save(
            role: Role.owner,
            update: BrandUpdate(
              name: 'Sri Lakshmi Textiles',
              colorHex: '#8B1E2D',
              logo: makePng(48, 48),
            ),
          ),
        );
        await pump(tester);
        expect(nameShown(tester), 'Sri Lakshmi Textiles');
        expect(find.byKey(const Key('brand-logo')), findsOneWidget);
        expect(find.byKey(const Key('brand-initial')), findsNothing);
        expect(primary(tester).toARGB32() & 0xFFFFFF, 0x8B1E2D);
      },
    );
    testWidgets('without a logo the mark is the first letter of the name', (
      tester,
    ) async {
      await tester.runAsync(
        () => repo.save(
          role: Role.owner,
          update: const BrandUpdate(name: 'madhu fashions'),
        ),
      );
      await openApp(tester);
      expect(find.text('M'), findsOneWidget);
      expect(nameShown(tester), 'madhu fashions');
    });
    testWidgets(
      'a logo that cannot be drawn falls back to the letter instead of breaking the screen',
      (tester) async {
        // a header that passes the size check but is not a decodable picture
        final broken = makePng(48, 48).sublist(0, 40);
        await tester.runAsync(
          () => db.customStatement(
            'INSERT OR REPLACE INTO app_settings (name, value) VALUES (?, ?)',
            ['brand_logo', _b64(broken)],
          ),
        );
        await openApp(tester);
        await pump(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('brand-name')), findsOneWidget);
      },
    );
    testWidgets(
      'the name and the main color show for a signed-in cashier and for the manager',
      (tester) async {
        await tester.runAsync(
          () => repo.save(
            role: Role.owner,
            update: const BrandUpdate(name: 'Corner Shop', colorHex: '#0F6B6B'),
          ),
        );
        await openApp(tester, signIn: true, manager: false);
        expect(nameShown(tester), 'Corner Shop');
        expect(find.text('Sales Mode'), findsOneWidget);
        expect(primary(tester).toARGB32() & 0xFFFFFF, 0x0F6B6B);
      },
    );
    testWidgets('Manager Mode shows the name too', (tester) async {
      await tester.runAsync(
        () => repo.save(
          role: Role.owner,
          update: const BrandUpdate(name: 'Corner Shop'),
        ),
      );
      await openApp(tester, signIn: true);
      expect(nameShown(tester), 'Corner Shop');
      expect(find.text('Manager Mode'), findsOneWidget);
    });
  });

  group('no hard-coded shop look', () {
    test(
      'no screen under lib/app/ui writes a product or shop name as text',
      () {
        for (final f in Directory('lib/app/ui').listSync().whereType<File>()) {
          if (!f.path.endsWith('.dart')) continue;
          final text = f.readAsStringSync();
          expect(text, isNot(contains("'Apparel PoS'")), reason: f.path);
          expect(text, isNot(contains('"Apparel PoS"')), reason: f.path);
        }
      },
    );
    test(
      'no screen sets a color from a literal hex except the shared brand code',
      () {
        // Colors come from the palette; status colors use the theme's scheme.
        // stock_entry_screen.dart has one amber text color for a warning: a status
        // color, not part of the shop's look.
        final allowed = {'brand_mark.dart', 'stock_entry_screen.dart'};
        for (final f in Directory('lib/app/ui').listSync().whereType<File>()) {
          final name = f.uri.pathSegments.last;
          if (!name.endsWith('.dart') || allowed.contains(name)) continue;
          expect(
            RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)').hasMatch(f.readAsStringSync()),
            isFalse,
            reason: name,
          );
        }
      },
    );
  });

  group('the data folder does not follow the shop name', () {
    test(
      'saving a name writes only a setting, nothing about the Windows identity',
      () async {
        await repo.save(
          role: Role.owner,
          update: const BrandUpdate(name: 'A Brand New Name'),
        );
        final rc = File('windows/runner/Runner.rc').readAsStringSync();
        expect(rc, contains('VALUE "CompanyName", "Apparel PoS"'));
        expect(rc, contains('VALUE "ProductName", "Apparel PoS"'));
        expect(rc, isNot(contains('A Brand New Name')));
      },
    );
  });

  group('titles carry the shop name', () {
    testWidgets('the daily report and the backups screen', (tester) async {
      await tester.runAsync(
        () => repo.save(
          role: Role.owner,
          update: const BrandUpdate(name: 'Corner Shop'),
        ),
      );
      await openApp(tester, signIn: true);
      await tester.tap(find.byKey(const Key('daily-report-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('report-title'))).data,
        'Daily report · Corner Shop',
      );
    });

    testWidgets('and the backups screen', (tester) async {
      await tester.runAsync(
        () => repo.save(
          role: Role.owner,
          update: const BrandUpdate(name: 'Corner Shop'),
        ),
      );
      await openApp(tester, signIn: true, svc: services(withBackup: true));
      await tester.tap(find.byKey(const Key('backups-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await pump(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('backups-title'))).data,
        'Backups · Corner Shop',
      );
    });
  });

  group('the printed paper', () {
    final fonts = LabelFonts(
      regular: File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync(),
      bold: File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync(),
    );
    test('the bill builds with a logo, and with none', () async {
      final bill = const BillSheet(
        shopName: 'Corner Shop',
        billNo: '2026-27/C1/000001',
        dateText: '22-11-2026 10:00',
        cashierName: 'Asha',
        customer: null,
        rows: [],
        totalText: '₹0.00',
        payments: [],
        changeText: null,
      );
      final plain = await buildBillPdf(bill, fonts);
      final withLogo = await buildBillPdf(bill, fonts, logo: makePng(64, 32));
      expect(String.fromCharCodes(withLogo.sublist(0, 5)), '%PDF-');
      expect(withLogo.length, greaterThan(plain.length));
    });
    test('the credit note slip builds with a logo, and with none', () async {
      const slip = CreditNoteSlip(
        shopName: 'Corner Shop',
        amountText: '₹499.00',
        code: '990001000019',
        noteNumber: 'C1-00001',
        issuedText: '22-11-2026 10:00',
        validTillText: '21-05-2027',
      );
      final plain = await buildCreditNoteSlipPdf(slip, fonts);
      final withLogo = await buildCreditNoteSlipPdf(
        slip,
        fonts,
        logo: makePng(64, 32),
      );
      expect(withLogo.length, greaterThan(plain.length));
    });
  });

  group('the development-only preview', () {
    Future<void> toPreview(WidgetTester tester, {bool preview = true}) async {
      await openApp(tester, signIn: true, svc: services(preview: preview));
    }

    testWidgets('is shown in a development run and hidden in a release run', (
      tester,
    ) async {
      await toPreview(tester, preview: false);
      expect(find.byKey(const Key('brand-preview-button')), findsNothing);
    });
    testWidgets('and never for a cashier', (tester) async {
      await openApp(
        tester,
        signIn: true,
        manager: false,
        svc: services(preview: true),
      );
      expect(find.byKey(const Key('brand-preview-button')), findsNothing);
    });
    testWidgets('and not when there is no brand controller to save to', (
      tester,
    ) async {
      await openApp(
        tester,
        signIn: true,
        svc: services(preview: true, withBrand: false),
      );
      expect(find.byKey(const Key('brand-preview-button')), findsNothing);
    });
    testWidgets(
      'trying a name, a tested color and a logo changes the screen at once',
      (tester) async {
        pickedLogo = makePng(40, 40);
        await toPreview(tester);
        await tester.tap(find.byKey(const Key('brand-preview-button')));
        await pump(tester);
        await tester.enterText(
          find.byKey(const Key('preview-name')),
          'Try Shop',
        );
        await tester.tap(find.byKey(const Key('preview-color-5'))); // Maroon
        await tester.pump();
        expect(
          tester.widget<Text>(find.byKey(const Key('preview-hex-note'))).data,
          'Readable with white text.',
        );
        await tester.tap(find.byKey(const Key('preview-logo')));
        await pump(tester);
        await tester.tap(find.byKey(const Key('preview-apply')));
        await pump(tester);
        expect(nameShown(tester), 'Try Shop');
        expect(primary(tester).toARGB32() & 0xFFFFFF, 0x8B1E2D);
        expect(find.byKey(const Key('brand-logo')), findsOneWidget);
        expect((await tester.runAsync(repo.load))!.name, 'Try Shop');
      },
    );
    testWidgets(
      'a color that is too light is explained and refused, and nothing changes',
      (tester) async {
        await toPreview(tester);
        await tester.tap(find.byKey(const Key('brand-preview-button')));
        await pump(tester);
        await tester.enterText(find.byKey(const Key('preview-hex')), '#FFEB3B');
        await tester.pump();
        expect(
          tester.widget<Text>(find.byKey(const Key('preview-hex-note'))).data,
          contains('Too light'),
        );
        await tester.tap(find.byKey(const Key('preview-apply')));
        await pump(tester);
        expect(find.byKey(const Key('preview-error')), findsOneWidget);
        expect(primary(tester).toARGB32() & 0xFFFFFF, 0x2B3A9F);
      },
    );
    testWidgets(
      'a logo that is not a picture is refused with a plain message',
      (tester) async {
        pickedLogo = Uint8List.fromList('not a picture'.codeUnits);
        await toPreview(tester);
        await tester.tap(find.byKey(const Key('brand-preview-button')));
        await pump(tester);
        await tester.tap(find.byKey(const Key('preview-logo')));
        await pump(tester);
        await tester.tap(find.byKey(const Key('preview-apply')));
        await pump(tester);
        expect(
          tester.widget<Text>(find.byKey(const Key('preview-error'))).data,
          contains('PNG or JPEG'),
        );
      },
    );
    testWidgets('the logo can be removed again', (tester) async {
      await tester.runAsync(
        () => repo.save(
          role: Role.owner,
          update: BrandUpdate(logo: makePng(40, 40)),
        ),
      );
      await toPreview(tester);
      expect(find.byKey(const Key('brand-logo')), findsOneWidget);
      await tester.tap(find.byKey(const Key('brand-preview-button')));
      await pump(tester);
      await tester.tap(find.byKey(const Key('preview-remove-logo')));
      await tester.tap(find.byKey(const Key('preview-apply')));
      await pump(tester);
      expect(find.byKey(const Key('brand-logo')), findsNothing);
      expect(find.byKey(const Key('brand-initial')), findsOneWidget);
    });
  });
}

String _b64(Uint8List bytes) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final out = StringBuffer();
  for (var i = 0; i < bytes.length; i += 3) {
    final b0 = bytes[i];
    final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
    final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
    out
      ..write(chars[b0 >> 2])
      ..write(chars[((b0 & 3) << 4) | (b1 >> 4)])
      ..write(i + 1 < bytes.length ? chars[((b1 & 15) << 2) | (b2 >> 6)] : '=')
      ..write(i + 2 < bytes.length ? chars[b2 & 63] : '=');
  }
  return out.toString();
}
