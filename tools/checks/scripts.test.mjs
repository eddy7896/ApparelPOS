// Run from the kit root: node --test tools/checks/scripts.test.mjs
// Each check is shown passing on a good project and failing on a deliberately bad one (05, section 8).
import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { evaluate } from './branch-policy.mjs';
import { runDrift } from './drift-check.mjs';
import { grade } from '../../evals/grade-answers.mjs';
import { parseTasks, seed } from '../hub/seed-plan.mjs';

function project(overrides = {}) {
  const root = mkdtempSync(join(tmpdir(), 'kit-drift-'));
  const files = {
    '.gitignore': '.env\n',
    'CLAUDE.md': '@AGENTS.md\n',
    'AGENTS.md': '# Project\n\n## Commands\n- `npm run check:drift`\n\n## Rules\n- See `documentation/guardrails.md`\n',
    'package.json': JSON.stringify({ scripts: { 'check:drift': 'node x.mjs' }, dependencies: { express: '1.0.0' } }),
    'documentation/guardrails.md': '# Guardrails\n',
    ...overrides,
  };
  for (const [name, body] of Object.entries(files)) {
    if (body === null) continue;
    mkdirSync(dirname(join(root, name)), { recursive: true });
    writeFileSync(join(root, name), body);
  }
  return root;
}
const ids = (findings) => findings.map((f) => f.id);
const goodDoc = '# Commands\n- `npm run check:drift`\n';

test('drift: a good project has no findings', () => assert.deepEqual(runDrift(project()), []));

test('doc-path fails on a missing path and passes when planned', () => {
  const root = project({ 'documentation/a.md': 'See `documentation/missing.md`.\n' });
  assert.ok(ids(runDrift(root)).includes('doc-path'));
  assert.deepEqual(runDrift(root, { plannedPaths: ['documentation/missing.md'] }), []);
});

test('doc-path fails on a broken relative link', () => {
  assert.ok(ids(runDrift(project({ 'documentation/a.md': '[x](nope.md)\n' }))).includes('doc-path'));
});

test('doc-path ignores branch names through ignorePathPatterns', () => {
  const root = project({ 'documentation/a.md': 'Use `documentation/x`, branch `app/api`.\n' });
  assert.ok(ids(runDrift(root, {})).includes('doc-path'));
  assert.deepEqual(runDrift(project({ 'documentation/a.md': 'Branch `app/api`.\n' }), { ignorePathPatterns: ['^app/'] }), []);
});

test('banned-dependency fails on package.json and on a lockfile-style manifest', () => {
  assert.ok(ids(runDrift(project(), { bannedDependencies: ['express'] })).includes('banned-dependency'));
  assert.ok(ids(runDrift(project({ 'requirements.txt': 'django==5\n' }), { bannedDependencies: ['django'] })).includes('banned-dependency'));
  assert.deepEqual(runDrift(project(), { bannedDependencies: ['expres'] }), []);
});

test('placeholder fails on each marker', () => {
  for (const marker of ['{{NAME}}', 'TBD', 'TODO(owner)']) {
    assert.ok(ids(runDrift(project({ 'documentation/a.md': `Value: ${marker}\n` }))).includes('placeholder'), marker);
  }
});

test('placeholder ignores exempt template folders', () => {
  assert.deepEqual(runDrift(project({ 'documentation/templates/a.md': '{{NAME}}\n' }), { pathCheckExemptDocs: ['documentation/templates'] }), []);
});

test('secrets-ignored fails without a .gitignore rule, on a .env file, and on a key', () => {
  assert.ok(ids(runDrift(project({ '.gitignore': 'dist\n' }))).includes('secrets-ignored'));
  assert.ok(ids(runDrift(project({ '.env.local': 'A=1\n' }))).includes('secrets-ignored'));
  const fakeKey = 'AKIA' + 'ABCDEFGHIJKLMNOP';
  const findings = runDrift(project({ 'src/a.txt': fakeKey }));
  assert.ok(ids(findings).includes('secrets-ignored'));
  assert.ok(!JSON.stringify(findings).includes(fakeKey), 'the secret must not be printed');
  assert.deepEqual(runDrift(project({ '.env.example': 'A=\n' })), []);
});

test('workflow-valid fails on structure and on a missing script', () => {
  const ok = 'on: push\njobs:\n  a:\n    steps:\n      - run: npm run check:drift\n';
  assert.deepEqual(runDrift(project({ '.github/workflows/a.yml': ok })), []);
  assert.ok(ids(runDrift(project({ '.github/workflows/a.yml': 'jobs:\n  a: 1\n' }))).includes('workflow-valid'));
  assert.ok(ids(runDrift(project({ '.github/workflows/a.yml': ok.replace('check:drift', 'nope') }))).includes('workflow-valid'));
});

test('entry-file-commands fails on a missing command, import, or file', () => {
  assert.ok(ids(runDrift(project({ 'AGENTS.md': goodDoc.replace('check:drift', 'nope') }))).includes('entry-file-commands'));
  assert.ok(ids(runDrift(project({ 'CLAUDE.md': 'separate content\n' }))).includes('entry-file-commands'));
  assert.ok(ids(runDrift(project({ 'AGENTS.md': null }))).includes('entry-file-commands'));
});

const policy = { prod: 'main', pre: 'staging', apps: { api: ['apps/api/'], web: ['apps/web/'] } };
const can = (head, base, changedFiles = []) => evaluate({ head, base, changedFiles }, policy).ok;

test('branch-policy allows every edge in the model', () => {
  for (const [h, b] of [['staging', 'main'], ['hotfix/a-b', 'main'], ['app/api', 'staging'], ['app/shared', 'staging'], ['cross/a', 'staging'], ['hotfix/a', 'staging'], ['main', 'staging'], ['feat/api/a-b', 'app/api'], ['fix/shared/a', 'app/shared'], ['staging', 'app/api']]) {
    assert.ok(can(h, b), `${h} -> ${b}`);
  }
});

test('branch-policy rejects forbidden edges and malformed names', () => {
  for (const [h, b] of [['app/api', 'main'], ['feat/api/a', 'staging'], ['feat/api/a', 'app/web'], ['cross/a', 'main'], ['feat/nope/a', 'app/api'], ['feat/api/Bad_Name', 'app/api'], ['app/nope', 'staging'], ['random', 'staging']]) {
    assert.ok(!can(h, b), `${h} -> ${b}`);
  }
});

test('branch-policy enforces ownership and exempts lockfiles', () => {
  assert.ok(can('app/api', 'staging', ['apps/api/a.ts', 'package-lock.json']));
  assert.ok(!can('app/api', 'staging', ['apps/web/a.ts']));
  assert.ok(!can('app/api', 'staging', ['tools/a.mjs']));
  assert.ok(can('app/shared', 'staging', ['tools/a.mjs']));
  assert.ok(!can('app/shared', 'staging', ['apps/api/a.ts']));
  assert.ok(can('staging', 'main', ['apps/api/a.ts', 'apps/web/a.ts']));
});

const golden = {
  passThreshold: 0.5,
  items: [
    { id: 'G-1', severity: 'critical', mustInclude: [['no', 'never'], ['api']], mustNotInclude: ['yes, if'] },
    { id: 'G-2', severity: 'high', mustInclude: [['unverified']] },
  ],
};

test('grader passes ideal answers, case-insensitively', () => {
  const r = grade(golden, { 'G-1': 'NEVER, only through the API', 'G-2': 'Unverified' });
  assert.equal(r.score, 1);
  assert.ok(r.ok);
});

test('grader fails a critical miss even above the threshold', () => {
  const r = grade(golden, { 'G-1': 'no', 'G-2': 'unverified' });
  assert.deepEqual(r.criticalFailures, ['G-1']);
  assert.ok(!r.ok);
});

test('grader fails on mustNotInclude, a missing answer, and below threshold', () => {
  assert.ok(!grade(golden, { 'G-1': 'no api, yes, if needed', 'G-2': 'unverified' }).ok);
  assert.equal(grade(golden, { 'G-1': 'no, api' }).results[1].pass, false);
  assert.ok(!grade({ ...golden, passThreshold: 1 }, { 'G-1': 'no, api', 'G-2': 'x' }).ok);
});

const table = '| ID | Task | Size | Acceptance | Depends on | Status |\n|---|---|---|---|---|---|\n| P1-3a | Server | M | E-1 | ADR-1 | todo |\n| P1-3b | Screen | M | E-2 | P1-3a | done |\n';

test('seed-plan keeps IDs, maps status, leaves todo at 0', () => {
  const plan = seed(parseTasks(table));
  assert.deepEqual(plan.items.map((t) => [t.id, t.phase, t.status, t.pct]), [['P1-3a', 1, 'todo', 0], ['P1-3b', 1, 'done', 100]]);
});

test('seed-plan fails on a duplicate ID, an unknown status, and a bad ID', () => {
  assert.throws(() => seed(parseTasks(table + '| P1-3a | Again | S | E | - | todo |\n')), /duplicate/);
  assert.throws(() => parseTasks(table.replace('todo', 'later')), /unknown status/);
  assert.throws(() => parseTasks(table.replace('P1-3a', 'X')), /bad task ID/);
});

test('seed-plan never resets progress on a second run', () => {
  const first = seed(parseTasks(table));
  first.items[0].status = 'doing';
  first.items[0].pct = 40;
  const again = seed(parseTasks(table + '| P1-4 | New | S | E | - | todo |\n'), first);
  assert.equal(again.items[0].pct, 40);
  assert.equal(again.items.length, 3);
  assert.equal(again.items[2].order, 3);
});
