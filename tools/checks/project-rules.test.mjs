import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { runProjectRules } from './project-rules.mjs';

function project(files) {
  const root = mkdtempSync(join(tmpdir(), 'rules-'));
  for (const [p, c] of Object.entries(files)) {
    mkdirSync(dirname(join(root, p)), { recursive: true });
    writeFileSync(join(root, p), c);
  }
  return root;
}
const ids = (root) => runProjectRules(root).map((f) => f.id);

test('a clean project has no findings', () => {
  const root = project({
    'packages/core_domain/lib/money.dart': 'final int totalPaise = 0;\n',
    'packages/sync_engine/lib/push.dart': "import 'package:cloud_firestore/cloud_firestore.dart';\n",
  });
  assert.deepEqual(runProjectRules(root), []);
});

test('money-float fails on a double or num money field', () => {
  assert.deepEqual(ids(project({ 'apps/pos_windows/lib/a.dart': 'double totalAmount = 1.5;\n' })), ['money-float']);
  assert.deepEqual(ids(project({ 'apps/pos_windows/lib/b.dart': 'num? mrp;\n' })), ['money-float']);
  assert.deepEqual(ids(project({ 'apps/pos_windows/lib/c.dart': 'final double taxRate = 0.05;\n' })), ['money-float']);
});

test('money-float ignores comments and non-money doubles', () => {
  assert.deepEqual(ids(project({ 'apps/pos_windows/lib/d.dart': '// double price = 1;\ndouble opacity = 0.5;\n' })), []);
});

test('firestore-import fails outside sync_engine', () => {
  const root = project({ 'apps/pos_windows/lib/e.dart': "import 'package:cloud_firestore/cloud_firestore.dart';\n" });
  assert.deepEqual(ids(root), ['firestore-import']);
});
