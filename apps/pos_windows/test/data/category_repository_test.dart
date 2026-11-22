// Stock categories (owner, 2026-11-23): groups and categories inside them, set
// up by the owner or a manager; styles are put in a category; cashiers can read
// the list for the lookup filter. E-AUDIT-1.
import 'package:core_domain/core_domain.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_windows/data/app_database.dart';
import 'package:pos_windows/data/category_repository.dart';
import 'package:pos_windows/data/stock_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late StockRepository stock;
  late CategoryRepository cats;
  var n = 0;
  String newId() => 'id-${++n}';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    n = 0;
    stock = StockRepository(db, newId: newId);
    cats = CategoryRepository(db, newId: newId);
    await stock.ensureCounter();
  });
  tearDown(() => db.close());

  Future<String> style(String name, {String? categoryId}) async {
    await stock.receivePurchase(
      role: Role.owner,
      categoryId: categoryId,
      draft: PurchaseDraft(
        supplier: 'S',
        style: name,
        lines: [
          PurchaseLine(
            size: 'M',
            color: 'Blue',
            quantity: 1,
            cost: Money(10000),
            mrp: Money(20000),
          ),
        ],
      ),
    );
    return (await db
            .customSelect(
              'SELECT id FROM products WHERE name = ?',
              variables: [Variable<String>(name)],
            )
            .getSingle())
        .read<String>('id');
  }

  Future<String> makeGroup(String name) =>
      cats.add(role: Role.owner, actorId: 'o', name: name);
  Future<String> makeCategory(
    String name,
    String parent, {
    Role role = Role.owner,
  }) => cats.add(role: role, actorId: 'o', name: name, parentId: parent);
  Future<List<String>> actions() async => [
    for (final r
        in await db
            .customSelect('SELECT action FROM audit_log ORDER BY rowid')
            .get())
      r.read<String>('action'),
  ];

  group('setting up groups and categories', () {
    test('the owner adds a group and a category inside it', () async {
      final men = await makeGroup('Men');
      final shirts = await makeCategory('Shirts', men);
      final list = await cats.list(role: Role.owner);
      expect(list.map((e) => e.node.name), ['Men', 'Shirts']);
      expect(list[1].node.parentId, men);
      expect(shirts, isNotEmpty);
    });

    test('a manager may too, a cashier and nobody may not', () async {
      await cats.add(role: Role.manager, actorId: 'm', name: 'Kids');
      await expectLater(
        cats.add(role: Role.cashier, actorId: 'c', name: 'X'),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        cats.add(role: null, actorId: 'c', name: 'X'),
        throwsA(isA<PermissionDenied>()),
      );
      expect((await cats.list(role: Role.owner)).length, 1);
    });

    test(
      'only two levels: a category cannot have a category inside it',
      () async {
        final men = await makeGroup('Men');
        final shirts = await makeCategory('Shirts', men);
        await expectLater(
          makeCategory('Formal', shirts),
          throwsA(isA<TooDeep>()),
        );
      },
    );

    test('the parent must exist', () async {
      await expectLater(
        makeCategory('Shirts', 'gone'),
        throwsA(isA<UnknownCategory>()),
      );
    });

    test('the name is cleaned, and a blank or odd one is refused', () async {
      await makeGroup('  Men   Wear ');
      expect((await cats.list(role: Role.owner)).single.node.name, 'Men Wear');
      for (final bad in [
        '  ',
        'a' * 41,
        r'Men\nWear'.replaceAll(r'\n', '\n'),
      ]) {
        await expectLater(
          makeGroup(bad),
          throwsA(isA<InvalidCategoryName>()),
          reason: bad,
        );
      }
    });

    test(
      'a name already used in the same place is refused, whatever the capitals',
      () async {
        final men = await makeGroup('Men');
        await makeCategory('Shirts', men);
        await expectLater(
          makeCategory('shirts', men),
          throwsA(isA<CategoryNameTaken>()),
        );
        await expectLater(makeGroup('MEN'), throwsA(isA<CategoryNameTaken>()));
        final women = await makeGroup('Women');
        await makeCategory('Shirts', women); // another group may reuse a name
        expect((await cats.list(role: Role.owner)).length, 4);
      },
    );

    test(
      'adding a category to a group that already has styles in it is refused',
      () async {
        final men = await makeGroup('Men');
        await style('Cotton Kurta', categoryId: men);
        await expectLater(
          makeCategory('Shirts', men),
          throwsA(isA<GroupHasStyles>()),
        );
      },
    );
  });

  group('renaming and removing', () {
    test('rename keeps the place; a clash or a bad name is refused; its own name in other capitals is fine', () async {
      final men = await makeGroup('Men');
      final shirts = await makeCategory('Shirts', men);
      await makeCategory('Jeans', men);
      await cats.rename(
        role: Role.manager,
        actorId: 'm',
        id: shirts,
        name: 'Formal Shirts',
      );
      expect((await cats.list(role: Role.owner)).map((e) => e.node.name), [
        'Men',
        'Formal Shirts',
        'Jeans',
      ]);
      await expectLater(
        cats.rename(role: Role.owner, actorId: 'o', id: shirts, name: 'jeans'),
        throwsA(isA<CategoryNameTaken>()),
      );
      await expectLater(
        cats.rename(role: Role.owner, actorId: 'o', id: shirts, name: ' '),
        throwsA(isA<InvalidCategoryName>()),
      );
      await cats.rename(
        role: Role.owner,
        actorId: 'o',
        id: shirts,
        name: 'FORMAL SHIRTS',
      );
    });

    test('an empty category can be removed; one with styles or categories in it cannot', () async {
      final men = await makeGroup('Men');
      final shirts = await makeCategory('Shirts', men);
      await style('Cotton Kurta', categoryId: shirts);
      await expectLater(
        cats.delete(role: Role.owner, actorId: 'o', id: shirts),
        throwsA(isA<CategoryInUse>()),
      );
      await expectLater(
        cats.delete(role: Role.owner, actorId: 'o', id: men),
        throwsA(isA<CategoryInUse>()),
      );
      final jeans = await makeCategory('Jeans', men);
      await cats.delete(role: Role.owner, actorId: 'o', id: jeans);
      expect((await cats.list(role: Role.owner)).map((e) => e.node.name), [
        'Men',
        'Shirts',
      ]);
    });

    test('a cashier cannot rename or remove', () async {
      final men = await makeGroup('Men');
      await expectLater(
        cats.rename(role: Role.cashier, actorId: 'c', id: men, name: 'X'),
        throwsA(isA<PermissionDenied>()),
      );
      await expectLater(
        cats.delete(role: Role.cashier, actorId: 'c', id: men),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('putting styles in categories', () {
    test('a style is put in a category and the list counts it', () async {
      final men = await makeGroup('Men');
      final shirts = await makeCategory('Shirts', men);
      final id = await style('Cotton Kurta');
      await cats.assignStyle(
        role: Role.manager,
        actorId: 'm',
        styleId: id,
        categoryId: shirts,
      );
      final list = await cats.list(role: Role.owner);
      expect(list.singleWhere((e) => e.node.id == shirts).styleCount, 1);
      expect((await cats.styles(role: Role.owner)).single.categoryId, shirts);
    });

    test('stock entry can name the category when it receives stock', () async {
      final men = await makeGroup('Men');
      final shirts = await makeCategory('Shirts', men);
      final id = await style('Cotton Kurta', categoryId: shirts);
      expect(
        (await cats.styles(role: Role.owner))
            .singleWhere((s) => s.id == id)
            .categoryId,
        shirts,
      );
    });

    test(
      'a group that has categories under it cannot take styles directly',
      () async {
        final men = await makeGroup('Men');
        await makeCategory('Shirts', men);
        final id = await style('Cotton Kurta');
        await expectLater(
          cats.assignStyle(
            role: Role.owner,
            actorId: 'o',
            styleId: id,
            categoryId: men,
          ),
          throwsA(isA<NotAssignable>()),
        );
        await expectLater(
          cats.assignStyle(
            role: Role.owner,
            actorId: 'o',
            styleId: id,
            categoryId: 'gone',
          ),
          throwsA(isA<NotAssignable>()),
        );
      },
    );

    test(
      'a group with no categories can be used as a category itself',
      () async {
        final kids = await makeGroup('Kids');
        final id = await style('Kids Tee', categoryId: kids);
        expect(
          (await cats.styles(role: Role.owner))
              .singleWhere((s) => s.id == id)
              .categoryId,
          kids,
        );
      },
    );

    test('passing no category takes a style out of its category', () async {
      final kids = await makeGroup('Kids');
      final id = await style('Kids Tee', categoryId: kids);
      await cats.assignStyle(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        categoryId: null,
      );
      expect((await cats.styles(role: Role.owner)).single.categoryId, isNull);
    });

    test(
      'stock entry with a category that cannot take styles saves nothing',
      () async {
        final men = await makeGroup('Men');
        await makeCategory('Shirts', men);
        await expectLater(
          style('Cotton Kurta', categoryId: men),
          throwsA(isA<NotAssignable>()),
        );
        expect(
          (await db
                  .customSelect('SELECT COUNT(*) AS c FROM products')
                  .getSingle())
              .read<int>('c'),
          0,
        );
      },
    );

    test('the category a style name already has is found for the stock entry prefill', () async {
      final kids = await makeGroup('Kids');
      await style('Kids Tee', categoryId: kids);
      expect(
        await cats.categoryOfStyleNamed(role: Role.owner, name: 'kids tee'),
        kids,
      );
      expect(
        await cats.categoryOfStyleNamed(role: Role.owner, name: 'Nothing'),
        isNull,
      );
    });

    test(
      'a cashier may read the list and the styles but not change them',
      () async {
        final kids = await makeGroup('Kids');
        final id = await style('Kids Tee');
        expect(await cats.list(role: Role.cashier), isNotEmpty);
        expect(await cats.styles(role: Role.cashier), isNotEmpty);
        await expectLater(
          cats.assignStyle(
            role: Role.cashier,
            actorId: 'c',
            styleId: id,
            categoryId: kids,
          ),
          throwsA(isA<PermissionDenied>()),
        );
        await expectLater(
          cats.list(role: null),
          throwsA(isA<PermissionDenied>()),
        );
      },
    );
  });

  group('the audit trail', () {
    test('each change is a row with the actor', () async {
      final men = await makeGroup('Men');
      final shirts = await makeCategory('Shirts', men);
      final id = await style('Cotton Kurta');
      await cats.assignStyle(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        categoryId: shirts,
      );
      await cats.rename(
        role: Role.owner,
        actorId: 'o',
        id: shirts,
        name: 'Formal',
      );
      await cats.assignStyle(
        role: Role.owner,
        actorId: 'o',
        styleId: id,
        categoryId: null,
      );
      await cats.delete(role: Role.owner, actorId: 'o', id: shirts);
      expect(
        await actions(),
        containsAllInOrder([
          'category.create',
          'category.create',
          'style.categorize',
          'category.rename',
          'style.categorize',
          'category.delete',
        ]),
      );
    });
  });
}
