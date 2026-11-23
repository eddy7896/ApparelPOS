// The shop's look as settings: placeholder defaults, validated saves, who may
// change it, and that a bad stored value never breaks a screen. UX-1.
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/brand_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

import '../support/png.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late BrandRepository repo;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    repo = BrandRepository(
      db,
      newId: newId,
      now: () => DateTime.utc(2026, 11, 22),
    );
  });
  tearDown(() => db.close());

  Future<void> setRaw(String name, String value) => db.customStatement(
    'INSERT OR REPLACE INTO app_settings (name, value) VALUES (?, ?)',
    [name, value],
  );

  group('before anything is set', () {
    test('the placeholder look: a placeholder name, the placeholder color, no logo', () async {
      final b = await repo.load();
      expect(b.name, isNull);
      expect(b.displayName, placeholderShopName);
      expect(b.color.hex, placeholderBrandColorHex);
      expect(b.hasLogo, isFalse);
      expect(b.isPlaceholder, isTrue);
    });
    test(
      'the placeholder color is readable, so a palette can always be built',
      () async {
        expect((await repo.load()).palette.onPrimary, 0xFFFFFF);
      },
    );
  });

  group('saving', () {
    test('name, color and logo are saved, cleaned, and read back', () async {
      final logo = makePng(64, 32);
      final b = await repo.save(
        role: Role.owner,
        update: BrandUpdate(
          name: '  Sri  Lakshmi Textiles ',
          colorHex: '1f6b3a',
          logo: logo,
        ),
      );
      expect(b.name, 'Sri Lakshmi Textiles');
      expect(b.color.hex, '#1F6B3A');
      expect(b.logo, logo);
      expect(b.isPlaceholder, isFalse);
      expect((await repo.load()).displayName, 'Sri Lakshmi Textiles');
    });
    test('a part left out is left alone', () async {
      await repo.save(
        role: Role.owner,
        update: const BrandUpdate(name: 'Shop A', colorHex: '#8B1E2D'),
      );
      final b = await repo.save(
        role: Role.owner,
        update: const BrandUpdate(name: 'Shop B'),
      );
      expect(b.name, 'Shop B');
      expect(b.color.hex, '#8B1E2D');
    });
    test('the logo can be removed', () async {
      await repo.save(
        role: Role.owner,
        update: BrandUpdate(logo: makePng(40, 40)),
      );
      expect((await repo.load()).hasLogo, isTrue);
      final b = await repo.save(
        role: Role.owner,
        update: const BrandUpdate(clearLogo: true),
      );
      expect(b.hasLogo, isFalse);
      expect(
        await db
            .customSelect(
              "SELECT COUNT(*) AS c FROM app_settings WHERE name = 'brand_logo'",
            )
            .getSingle()
            .then((r) => r.read<int>('c')),
        0,
      );
    });
    test('an empty update changes and writes nothing', () async {
      await repo.save(role: Role.owner, update: const BrandUpdate());
      expect(
        await db
            .customSelect(
              "SELECT COUNT(*) AS c FROM audit_log WHERE action = 'brand.update'",
            )
            .getSingle()
            .then((r) => r.read<int>('c')),
        0,
      );
    });
    test('uses the same shop name setting the hangtags read', () async {
      await repo.save(
        role: Role.owner,
        update: const BrandUpdate(name: 'My Shop'),
      );
      final stock = StockRepository(db, newId: newId);
      expect(await stock.shopName(), 'My Shop');
      await stock.setShopName(role: Role.owner, name: 'Renamed Shop');
      expect((await repo.load()).name, 'Renamed Shop');
    });
  });

  group('refusals leave nothing behind', () {
    test('a blank, too long or control-character name', () async {
      for (final bad in [
        '',
        '   ',
        'x' * (maxShopNameLength + 1),
        'two\nlines',
      ]) {
        await expectLater(
          repo.save(
            role: Role.owner,
            update: BrandUpdate(name: bad),
          ),
          throwsA(isA<InvalidBrand>().having((e) => e.field, 'field', 'name')),
          reason: bad,
        );
      }
    });
    test('a color that is not a color, or too light for white text', () async {
      await expectLater(
        repo.save(
          role: Role.owner,
          update: const BrandUpdate(colorHex: 'blue'),
        ),
        throwsA(isA<InvalidBrand>().having((e) => e.field, 'field', 'color')),
      );
      await expectLater(
        repo.save(
          role: Role.owner,
          update: const BrandUpdate(colorHex: '#FFEB3B'),
        ),
        throwsA(
          isA<InvalidBrand>().having(
            (e) => e.message,
            'message',
            contains('too light'),
          ),
        ),
      );
    });
    test('a logo that is not a picture, too big or too small', () async {
      for (final bad in [
        Uint8List.fromList(utf8.encode('<svg/>')),
        makePng(8, 8),
        makePng(600, 10),
      ]) {
        await expectLater(
          repo.save(
            role: Role.owner,
            update: BrandUpdate(logo: bad),
          ),
          throwsA(isA<InvalidBrand>().having((e) => e.field, 'field', 'logo')),
        );
      }
    });
    test('one bad part saves none of the others', () async {
      await expectLater(
        repo.save(
          role: Role.owner,
          update: const BrandUpdate(name: 'Good Name', colorHex: '#FFEB3B'),
        ),
        throwsA(isA<InvalidBrand>()),
      );
      expect((await repo.load()).name, isNull);
      expect(
        await db
            .customSelect('SELECT COUNT(*) AS c FROM app_settings')
            .getSingle()
            .then((r) => r.read<int>('c')),
        0,
      );
    });
  });

  group('who may change it', () {
    test('a manager and the owner may; a cashier and nobody may not', () async {
      await repo.save(
        role: Role.manager,
        update: const BrandUpdate(name: 'By Manager'),
      );
      await repo.save(
        role: Role.owner,
        update: const BrandUpdate(name: 'By Owner'),
      );
      for (final role in [Role.cashier, null]) {
        await expectLater(
          repo.save(
            role: role,
            update: const BrandUpdate(name: 'Nope'),
          ),
          throwsA(isA<PermissionDenied>()),
        );
      }
      expect((await repo.load()).name, 'By Owner');
    });
    test('anyone can read it (the sign-in screen needs it)', () async {
      await repo.save(
        role: Role.owner,
        update: const BrandUpdate(name: 'Open Shop'),
      );
      expect((await repo.load()).displayName, 'Open Shop');
    });
  });

  group('audit and outbox', () {
    test('say which parts changed, never the values or the logo', () async {
      await repo.save(
        role: Role.owner,
        actor: 'owner-1',
        update: BrandUpdate(
          name: 'Secretive Shop',
          colorHex: '#2B3A9F',
          logo: makePng(40, 40),
        ),
      );
      final audit = await db
          .customSelect("SELECT * FROM audit_log WHERE action = 'brand.update'")
          .getSingle();
      final outbox = await db
          .customSelect(
            "SELECT payload FROM outbox WHERE operation = 'brand.update'",
          )
          .getSingle();
      expect(audit.read<String>('actor'), 'owner-1');
      for (final t in [
        audit.read<String>('details'),
        outbox.read<String>('payload'),
      ]) {
        expect(t, contains('name'));
        expect(t, contains('color'));
        expect(t, contains('logo'));
        expect(t, isNot(contains('Secretive')));
        expect(t, isNot(contains('2B3A9F')));
      }
    });
  });

  group('a bad stored value never breaks a screen', () {
    test(
      'a color that is too light falls back to the placeholder color',
      () async {
        await setRaw('brand_color', '#FFFF00');
        expect((await repo.load()).color.hex, placeholderBrandColorHex);
      },
    );
    test('a color that is not a color falls back', () async {
      await setRaw('brand_color', 'greenish');
      expect((await repo.load()).color.hex, placeholderBrandColorHex);
    });
    test(
      'a logo that is not a picture, or not even base64, is ignored',
      () async {
        await setRaw(
          'brand_logo',
          base64Encode(utf8.encode('not a picture at all, just text')),
        );
        expect((await repo.load()).hasLogo, isFalse);
        await setRaw('brand_logo', '%%% not base64 %%%');
        expect((await repo.load()).hasLogo, isFalse);
      },
    );
    test(
      'a stored name with a new line falls back to the placeholder name',
      () async {
        await setRaw('shop_name', 'Two\nLines');
        final b = await repo.load();
        expect(b.name, isNull);
        expect(b.displayName, placeholderShopName);
      },
    );
  });

  test(
    'the look is shop data: it lives in the database, so a backup holds it',
    () async {
      await repo.save(
        role: Role.owner,
        update: BrandUpdate(
          name: 'Backed Up',
          colorHex: '#6A2C70',
          logo: makePng(32, 32),
        ),
      );
      final rows = await db
          .customSelect(
            "SELECT name FROM app_settings WHERE name IN ('shop_name','brand_color','brand_logo') ORDER BY name",
          )
          .get();
      expect(
        [for (final r in rows) r.read<String>('name')],
        ['brand_color', 'brand_logo', 'shop_name'],
      );
    },
  );
}
