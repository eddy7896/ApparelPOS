import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

CategoryNode n(String id, String name, {String? parent}) =>
    CategoryNode(id: id, name: name, parentId: parent);

void main() {
  group('cleanCategoryName', () {
    test('trims and squeezes spaces', () {
      expect(cleanCategoryName('  Men   Shirts '), 'Men Shirts');
    });
    test('blank, too long and control characters are refused', () {
      expect(cleanCategoryName('   '), isNull);
      expect(cleanCategoryName('a' * 41), isNull);
      expect(cleanCategoryName('a' * 40), 'a' * 40);
      expect(cleanCategoryName('Men\nShirts'), isNull);
    });
    test('any language is fine', () {
      expect(cleanCategoryName('कुर्ता'), 'कुर्ता');
    });
  });

  group('two levels only', () {
    final tree = [n('men', 'Men'), n('shirts', 'Shirts', parent: 'men')];
    test('a group (no parent) may have categories', () {
      expect(canHaveChildren(tree[0]), isTrue);
    });
    test('a category inside a group may not have children', () {
      expect(canHaveChildren(tree[1]), isFalse);
    });
  });

  group('categoryPath', () {
    final tree = [
      n('men', 'Men'),
      n('shirts', 'Shirts', parent: 'men'),
      n('kids', 'Kids'),
    ];
    test('a category shows its group', () {
      expect(categoryPath(tree, 'shirts'), 'Men › Shirts');
    });
    test('a group alone is just its name', () {
      expect(categoryPath(tree, 'kids'), 'Kids');
    });
    test('no category is "No category"', () {
      expect(categoryPath(tree, null), 'No category');
    });
    test('an id that no longer exists is "No category", not a crash', () {
      expect(categoryPath(tree, 'gone'), 'No category');
    });
  });

  group(
    'isAssignable: a style goes in a category with no categories under it',
    () {
      final tree = [
        n('men', 'Men'),
        n('shirts', 'Shirts', parent: 'men'),
        n('kids', 'Kids'),
      ];
      test('a group that has categories is not assignable', () {
        expect(isAssignable(tree, 'men'), isFalse);
      });
      test('a category is', () {
        expect(isAssignable(tree, 'shirts'), isTrue);
      });
      test('a group with no categories is assignable itself', () {
        expect(isAssignable(tree, 'kids'), isTrue);
      });
      test('unknown is not', () {
        expect(isAssignable(tree, 'gone'), isFalse);
      });
    },
  );

  group('nameTaken (unique among siblings, capitals ignored)', () {
    final tree = [
      n('men', 'Men'),
      n('shirts', 'Shirts', parent: 'men'),
      n('shirts2', 'Shirts', parent: 'women'),
      n('women', 'Women'),
    ];
    test('the same name under the same group is taken', () {
      expect(nameTaken(tree, 'shirts', parentId: 'men'), isTrue);
    });
    test('the same name under another group is fine', () {
      expect(nameTaken(tree, 'Shirts', parentId: 'kids'), isFalse);
    });
    test('top-level names are unique among top-level names', () {
      expect(nameTaken(tree, 'MEN', parentId: null), isTrue);
      expect(nameTaken(tree, 'Shirts', parentId: null), isFalse);
    });
    test('renaming to its own name is not a clash', () {
      expect(
        nameTaken(tree, 'Shirts', parentId: 'men', exceptId: 'shirts'),
        isFalse,
      );
    });
  });

  group('groupOf (the top-level group a node rolls up into)', () {
    final tree = [
      n('men', 'Men'),
      n('shirts', 'Shirts', parent: 'men'),
      n('kids', 'Kids'),
    ];
    test('a category rolls up into its group', () {
      expect(groupOf(tree, 'shirts'), 'men');
    });
    test('a group is its own group', () {
      expect(groupOf(tree, 'men'), 'men');
      expect(groupOf(tree, 'kids'), 'kids');
    });
    test('none and unknown have no group', () {
      expect(groupOf(tree, null), isNull);
      expect(groupOf(tree, 'gone'), isNull);
    });
  });

  group('sortedTree', () {
    test('groups by name, each followed by its categories by name', () {
      final out = sortedTree([
        n('b', 'Women'),
        n('b2', 'Kurtas', parent: 'b'),
        n('a', 'Men'),
        n('a2', 'Shirts', parent: 'a'),
        n('a1', 'Jeans', parent: 'a'),
      ]);
      expect(out.map((e) => e.name), [
        'Men',
        'Jeans',
        'Shirts',
        'Women',
        'Kurtas',
      ]);
    });
  });

  group('categoryMatches (the lookup filter)', () {
    final tree = [
      n('men', 'Men'),
      n('shirts', 'Shirts', parent: 'men'),
      n('jeans', 'Jeans', parent: 'men'),
      n('kids', 'Kids'),
    ];
    test('no filter keeps everything, categorised or not', () {
      expect(categoryMatches(tree, null, 'shirts'), isTrue);
      expect(categoryMatches(tree, null, null), isTrue);
    });
    test('a category keeps only its own styles', () {
      expect(categoryMatches(tree, 'shirts', 'shirts'), isTrue);
      expect(categoryMatches(tree, 'shirts', 'jeans'), isFalse);
      expect(categoryMatches(tree, 'shirts', null), isFalse);
    });
    test('a group keeps every category inside it, and styles put in the group itself', () {
      expect(categoryMatches(tree, 'men', 'shirts'), isTrue);
      expect(categoryMatches(tree, 'men', 'jeans'), isTrue);
      expect(categoryMatches(tree, 'men', 'kids'), isFalse);
      expect(categoryMatches(tree, 'kids', 'kids'), isTrue);
    });
    test('the No category filter keeps only styles with none', () {
      expect(categoryMatches(tree, noCategoryFilter, null), isTrue);
      expect(categoryMatches(tree, noCategoryFilter, 'shirts'), isFalse);
    });
    test('a style whose category was removed counts as having none', () {
      expect(categoryMatches(tree, noCategoryFilter, 'gone'), isTrue);
      expect(categoryMatches(tree, 'men', 'gone'), isFalse);
    });
  });

  group('sumByCategory (analytics roll-up)', () {
    final tree = [
      n('men', 'Men'),
      n('shirts', 'Shirts', parent: 'men'),
      n('jeans', 'Jeans', parent: 'men'),
      n('kids', 'Kids'),
    ];
    final data = <String?, int>{
      'shirts': 5,
      'jeans': 3,
      'kids': 2,
      null: 4,
      'gone': 1,
    };

    test(
      'by category keeps each category; a removed or missing one is "none"',
      () {
        final r = sumByCategory(tree, data, byGroup: false);
        expect(r['shirts'], 5);
        expect(r['jeans'], 3);
        expect(r['kids'], 2);
        expect(r[null], 5); // null 4 + removed 1
        expect(r.containsKey('gone'), isFalse);
      },
    );

    test('by group adds the categories inside each group', () {
      final r = sumByCategory(tree, data, byGroup: true);
      expect(r['men'], 8);
      expect(r['kids'], 2);
      expect(r[null], 5);
      expect(r.containsKey('shirts'), isFalse);
    });

    test('the total never changes', () {
      for (final g in [true, false]) {
        expect(
          sumByCategory(tree, data, byGroup: g).values.fold(0, (a, b) => a + b),
          15,
        );
      }
    });

    test('an empty map gives an empty map', () {
      expect(sumByCategory(tree, const {}, byGroup: true), isEmpty);
    });
  });
}
