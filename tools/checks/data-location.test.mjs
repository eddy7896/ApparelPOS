import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { evaluate } from './data-location.mjs';

const identity = JSON.parse(readFileSync(new URL('./windows-identity.json', import.meta.url), 'utf8'));
const good = {
  rcText: 'VALUE "CompanyName", "Apparel PoS" "\\0"\nVALUE "ProductName", "Apparel PoS" "\\0"',
  mainCppText: 'if (!window.Create(L"Apparel PoS", origin, size)) {',
  installerText: `[Setup]\nAppId=${identity.installerAppId}\nAppName=x`,
  identity,
};

test('the real files in this repository pass', () => {
  const read = (p) => readFileSync(new URL(`../../${p}`, import.meta.url), 'utf8');
  const r = evaluate({
    rcText: read(identity.rc),
    mainCppText: read(identity.mainCpp),
    installerText: read(identity.installerScript),
    identity,
  });
  assert.deepEqual(r.errors, []);
  assert.equal(r.ok, true);
});

test('matching values pass', () => {
  assert.deepEqual(evaluate(good), { ok: true, errors: [] });
});

test('a changed company name is caught', () => {
  const r = evaluate({ ...good, rcText: good.rcText.replace('"CompanyName", "Apparel PoS"', '"CompanyName", "Other"') });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /CompanyName/);
});

test('a changed product name is caught', () => {
  const r = evaluate({ ...good, rcText: good.rcText.replace('"ProductName", "Apparel PoS"', '"ProductName", "pos_windows"') });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /ProductName/);
});

test('a missing company name is caught', () => {
  const r = evaluate({ ...good, rcText: 'VALUE "ProductName", "Apparel PoS" "\\0"' });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /CompanyName is null/);
});

test('a changed window title is caught', () => {
  const r = evaluate({ ...good, mainCppText: 'window.Create(L"pos_windows", origin, size)' });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /window title/);
});

test('a changed installer AppId is caught', () => {
  const r = evaluate({ ...good, installerText: 'AppId={{00000000-0000-0000-0000-000000000000}' });
  assert.equal(r.ok, false);
  assert.match(r.errors[0], /AppId/);
});

test('a missing file is caught, not ignored', () => {
  const r = evaluate({ ...good, rcText: null, mainCppText: null, installerText: null });
  assert.equal(r.ok, false);
  assert.equal(r.errors.length, 4);
});

test('several changes are all reported', () => {
  const r = evaluate({
    rcText: 'VALUE "CompanyName", "x" "\\0"\nVALUE "ProductName", "y" "\\0"',
    mainCppText: 'window.Create(L"z", o, s)',
    installerText: 'AppId=q',
    identity,
  });
  assert.equal(r.errors.length, 4);
});
