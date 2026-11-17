#!/usr/bin/env node
// Branch policy: section 3 of 06-git-branching-and-pr.md. Zero dependencies.
// Usage in CI: node tools/checks/branch-policy.mjs --config tools/checks/branch-policy.json
// Head and base come from GITHUB_HEAD_REF and GITHUB_BASE_REF (or --head and --base), never from the PR title.
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { basename, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const LOCKFILES = new Set(['package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'pubspec.lock', 'Cargo.lock', 'go.sum', 'poetry.lock']);
const KEBAB = '[a-z0-9]+(?:-[a-z0-9]+)*';

// Simple model (ADR-0013, one builder): topic -> pre -> prod, hotfix -> prod then back-merge. Selected by "simple": true.
function evaluateSimple({ head, base }, config) {
  const { prod, pre } = config;
  const errors = [];
  const isHotfix = new RegExp(`^hotfix/${KEBAB}$`).test(head);
  const isTopic = new RegExp(`^(feat|fix|chore)/${KEBAB}$`).test(head);
  if (/^(feat|fix|chore|hotfix)\//.test(head) && !isTopic && !isHotfix) errors.push(`malformed branch name: ${head}`);
  if (errors.length) return { ok: false, errors };
  let allowed = false;
  if (base === prod) allowed = head === pre || isHotfix;
  else if (base === pre) allowed = isTopic || isHotfix || head === prod;
  if (!allowed) errors.push(`merge from ${head} into ${base} is not allowed`);
  return { ok: errors.length === 0, errors };
}

export function evaluate({ head, base, changedFiles = [] }, config) {
  if (config.simple) return evaluateSimple({ head, base }, config);
  const { prod, pre, apps } = config;
  const errors = [];
  const known = [...Object.keys(apps), 'shared'];
  const appOf = (b) => (b.startsWith('app/') && known.includes(b.slice(4)) ? b.slice(4) : null);
  const headApp = appOf(head);
  const baseApp = appOf(base);
  const isHotfix = new RegExp(`^hotfix/${KEBAB}$`).test(head);
  const isCross = new RegExp(`^cross/${KEBAB}$`).test(head);
  const topic = head.match(new RegExp(`^(feat|fix|chore)/([^/]+)/(${KEBAB})$`));
  const isTopic = Boolean(topic && known.includes(topic[2]));

  if (/^(feat|fix|chore)\//.test(head) && !isTopic) errors.push(`malformed topic branch name: ${head}`);
  if (head.startsWith('cross/') && !isCross) errors.push(`malformed cross branch name: ${head}`);
  if (head.startsWith('hotfix/') && !isHotfix) errors.push(`malformed hotfix branch name: ${head}`);
  if (head.startsWith('app/') && !headApp) errors.push(`unknown app branch: ${head}`);
  if (errors.length) return { ok: false, errors };

  let allowed = false;
  if (base === prod) allowed = head === pre || isHotfix;
  else if (base === pre) allowed = Boolean(headApp) || isCross || isHotfix || head === prod;
  else if (baseApp) allowed = (isTopic && topic[2] === baseApp) || head === pre;
  if (!allowed) errors.push(`merge from ${head} into ${base} is not allowed`);

  if (allowed && base === pre && headApp) {
    const isLock = (f) => LOCKFILES.has(basename(f));
    const owners = (f) => Object.entries(apps).filter(([, paths]) => paths.some((p) => f.startsWith(p))).map(([a]) => a);
    for (const f of changedFiles) {
      if (isLock(f)) continue;
      const own = owners(f);
      if (headApp === 'shared' ? own.length > 0 : !own.includes(headApp)) errors.push(`${head} may not change ${f}`);
    }
  }
  return { ok: errors.length === 0, errors };
}

function arg(argv, name, fallback) {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : fallback;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const config = JSON.parse(readFileSync(arg(argv, '--config', 'tools/checks/branch-policy.json'), 'utf8'));
  const head = arg(argv, '--head', process.env.GITHUB_HEAD_REF);
  const base = arg(argv, '--base', process.env.GITHUB_BASE_REF);
  if (!head || !base) { console.error('head and base are required (--head/--base or GITHUB_HEAD_REF/GITHUB_BASE_REF)'); process.exit(2); }
  const filesArg = arg(argv, '--files');
  const raw = filesArg
    ? readFileSync(filesArg, 'utf8')
    : execFileSync('git', ['diff', '--name-only', `origin/${base}...HEAD`], { encoding: 'utf8' });
  const result = evaluate({ head, base, changedFiles: raw.split('\n').filter(Boolean) }, config);
  for (const e of result.errors) console.log(`error [branch-policy] ${e}`);
  console.log(result.ok ? `branch-policy: ${head} -> ${base} ok` : `branch-policy: ${result.errors.length} errors`);
  process.exit(result.ok ? 0 : 1);
}
