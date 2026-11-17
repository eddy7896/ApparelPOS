import assert from 'node:assert/strict';
import { test } from 'node:test';
import { evaluate } from './branch-policy.mjs';

const config = { simple: true, prod: 'main', pre: 'develop', apps: {} };
const ok = (head, base) => evaluate({ head, base }, config).ok;

test('E-BRANCH-1 simple model allows every edge', () => {
  assert.ok(ok('feat/billing-register', 'develop'));
  assert.ok(ok('fix/rounding', 'develop'));
  assert.ok(ok('chore/ci', 'develop'));
  assert.ok(ok('develop', 'main'));
  assert.ok(ok('hotfix/cash-close', 'main'));
  assert.ok(ok('hotfix/cash-close', 'develop'));
  assert.ok(ok('main', 'develop'));
});

test('E-BRANCH-2 simple model rejects forbidden edges and bad names', () => {
  assert.ok(!ok('feat/billing-register', 'main'));
  assert.ok(!ok('develop', 'feat/x'));
  assert.ok(!ok('random', 'develop'));
  assert.ok(!ok('feat/Bad_Name', 'develop'));
  assert.ok(!ok('feat/a/b', 'develop'));
  assert.ok(!ok('main', 'main'));
});
