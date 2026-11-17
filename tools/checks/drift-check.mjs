#!/usr/bin/env node
// Drift check: checks 1 to 6 of 05-drift-evals-tests.md. Zero dependencies.
// Usage: node tools/checks/drift-check.mjs [--root .] [--config tools/checks/drift-config.json] [--strict]
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { basename, dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SKIP_DIRS = new Set(['.git', 'node_modules', 'dist', 'build', '.next', 'coverage', 'vendor']);
const MANIFESTS = new Set(['package.json', 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'requirements.txt', 'pyproject.toml', 'go.mod', 'pubspec.yaml', 'Cargo.toml']);
const KEY_PATTERNS = [/AKIA[0-9A-Z]{16}/, /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/, /ghp_[A-Za-z0-9]{36}/, /sk-[A-Za-z0-9_-]{32,}/, /AIza[0-9A-Za-z_-]{35}/, /xox[baprs]-[A-Za-z0-9-]{10,}/];
const MAX_SCAN_BYTES = 1024 * 1024;

function walk(root, dir = root, out = []) {
  for (const name of readdirSync(dir)) {
    if (SKIP_DIRS.has(name)) continue;
    const full = join(dir, name);
    if (statSync(full).isDirectory()) walk(root, full, out);
    else out.push(relative(root, full).split('\\').join('/'));
  }
  return out;
}

function trackedFiles(root) {
  try {
    return execFileSync('git', ['ls-files'], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).split('\n').filter(Boolean);
  } catch {
    return walk(root);
  }
}

const isUnder = (path, prefix) => path === prefix || path.startsWith(prefix.replace(/\/$/, '') + '/');

function docFiles(root, config) {
  const exempt = config.pathCheckExemptDocs || [];
  const docs = existsSync(join(root, 'documentation')) ? walk(root, join(root, 'documentation')).filter((f) => f.endsWith('.md')) : [];
  if (existsSync(join(root, 'AGENTS.md'))) docs.unshift('AGENTS.md');
  return docs.filter((f) => !exempt.some((e) => isUnder(f, e)));
}

function checkDocPaths(root, config, add) {
  const planned = config.plannedPaths || [];
  const ignore = (config.ignorePathPatterns || []).map((p) => new RegExp(p));
  const roots = new Set(config.pathRoots || []);
  const known = (p) => existsSync(join(root, p)) || planned.some((x) => isUnder(p, x));
  for (const doc of docFiles(root, config)) {
    const text = readFileSync(join(root, doc), 'utf8');
    for (const [, raw] of text.matchAll(/`([^`\n]+)`/g)) {
      const token = raw.replace(/\/$/, '');
      if (!token.includes('/') || /[\s<>{}*$@:?=|,()[\]]/.test(token) || token.startsWith('/') || token.startsWith('~') || token.startsWith('.')) continue;
      if (ignore.some((r) => r.test(token))) continue;
      const first = token.split('/')[0];
      const hasExt = /\.[A-Za-z0-9]+$/.test(basename(token));
      if (!hasExt && !roots.has(first) && !existsSync(join(root, first))) continue;
      if (!known(token)) add('error', 'doc-path', `path does not exist and is not in plannedPaths: ${token}`, doc);
    }
    for (const [, target] of text.matchAll(/\]\(([^)\s#]+)(?:#[^)]*)?\)/g)) {
      if (/^[a-z]+:/i.test(target)) continue;
      const p = relative(root, resolve(root, dirname(doc), target)).split('\\').join('/');
      if (!known(p)) add('error', 'doc-path', `link target does not exist: ${target}`, doc);
    }
  }
}

function checkBanned(root, config, add) {
  const banned = config.bannedDependencies || [];
  if (!banned.length) return;
  for (const file of walk(root).filter((f) => MANIFESTS.has(basename(f)))) {
    const text = readFileSync(join(root, file), 'utf8');
    if (basename(file) === 'package.json') {
      let pkg;
      try { pkg = JSON.parse(text); } catch { add('error', 'banned-dependency', 'manifest is not valid JSON', file); continue; }
      const deps = ['dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies'].flatMap((k) => Object.keys(pkg[k] || {}));
      for (const name of banned) if (deps.includes(name)) add('error', 'banned-dependency', `banned dependency: ${name}`, file);
    } else {
      for (const name of banned) {
        const safe = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        if (new RegExp(`(^|[^A-Za-z0-9_-])${safe}([^A-Za-z0-9_-]|$)`, 'm').test(text)) add('error', 'banned-dependency', `banned dependency: ${name}`, file);
      }
    }
  }
}

function checkPlaceholders(root, config, add) {
  for (const doc of docFiles(root, config)) {
    const text = readFileSync(join(root, doc), 'utf8');
    text.split('\n').forEach((line, i) => {
      const m = line.match(/\{\{[A-Za-z0-9_ -]+\}\}|\bTBD\b|TODO\(owner\)/);
      if (m) add('error', 'placeholder', `unfilled placeholder ${m[0]} on line ${i + 1}`, doc);
    });
  }
}

function checkSecrets(root, add) {
  const gitignore = existsSync(join(root, '.gitignore')) ? readFileSync(join(root, '.gitignore'), 'utf8').split('\n').map((l) => l.trim()) : [];
  if (!gitignore.some((l) => l === '.env' || l === '.env*' || l === '*.env')) add('error', 'secrets-ignored', '.gitignore does not ignore .env files', '.gitignore');
  for (const file of trackedFiles(root)) {
    const name = basename(file);
    if (/^\.env(\..+)?$/.test(name) && !name.endsWith('.example')) add('error', 'secrets-ignored', 'environment file is tracked', file);
    const full = join(root, file);
    if (!existsSync(full) || !statSync(full).isFile() || statSync(full).size > MAX_SCAN_BYTES) continue;
    const buf = readFileSync(full);
    if (buf.includes(0)) continue;
    const text = buf.toString('utf8');
    // The matched text is never printed, so a finding cannot leak the secret into CI logs.
    if (KEY_PATTERNS.some((r) => r.test(text))) add('error', 'secrets-ignored', 'file contains a key-like string', file);
  }
}

function commandProblems(root, text) {
  const problems = [];
  let scripts = {};
  if (existsSync(join(root, 'package.json'))) {
    try { scripts = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).scripts || {}; } catch { problems.push('package.json is not valid JSON'); }
  }
  for (const [, name] of text.matchAll(/\bnpm run ([A-Za-z0-9:_-]+)/g)) if (!scripts[name]) problems.push(`npm script does not exist: ${name}`);
  for (const [, name] of text.matchAll(/\bnpm (test|start)\b/g)) if (!scripts[name]) problems.push(`npm script does not exist: ${name}`);
  for (const [, file] of text.matchAll(/\bnode (?:--[a-z-]+ )*([A-Za-z0-9_./-]+\.m?js)\b/g)) if (!existsSync(join(root, file))) problems.push(`script file does not exist: ${file}`);
  const make = existsSync(join(root, 'Makefile')) ? readFileSync(join(root, 'Makefile'), 'utf8') : '';
  for (const [, target] of text.matchAll(/\bmake ([A-Za-z0-9_-]+)/g)) if (!new RegExp(`^${target}\\s*:`, 'm').test(make)) problems.push(`make target does not exist: ${target}`);
  return problems;
}

function checkWorkflows(root, add) {
  const dir = join(root, '.github', 'workflows');
  if (!existsSync(dir)) return;
  for (const name of readdirSync(dir).filter((f) => /\.ya?ml$/.test(f))) {
    const file = `.github/workflows/${name}`;
    const text = readFileSync(join(dir, name), 'utf8');
    // Structural only: a real YAML parser would need a dependency. See 05, section 7.
    if (/^ *\t/m.test(text)) add('error', 'workflow-valid', 'indentation contains a tab', file);
    if (!/^("?on"?)\s*:/m.test(text)) add('error', 'workflow-valid', 'missing top-level "on:"', file);
    if (!/^jobs\s*:/m.test(text)) add('error', 'workflow-valid', 'missing top-level "jobs:"', file);
    for (const p of commandProblems(root, text)) add('error', 'workflow-valid', p, file);
  }
}

function checkEntryFile(root, add) {
  if (!existsSync(join(root, 'AGENTS.md'))) { add('error', 'entry-file-commands', 'AGENTS.md does not exist', 'AGENTS.md'); return; }
  const claude = join(root, 'CLAUDE.md');
  if (!existsSync(claude) || !readFileSync(claude, 'utf8').includes('@AGENTS.md')) add('error', 'entry-file-commands', 'CLAUDE.md must import @AGENTS.md', 'CLAUDE.md');
  const text = readFileSync(join(root, 'AGENTS.md'), 'utf8');
  const section = text.match(/^#+ .*Commands.*\n([\s\S]*?)(?=^#+ |(?![\s\S]))/im);
  if (!section) { add('error', 'entry-file-commands', 'AGENTS.md has no Commands section', 'AGENTS.md'); return; }
  for (const p of commandProblems(root, section[1])) add('error', 'entry-file-commands', p, 'AGENTS.md');
}

export function runDrift(root, config = {}) {
  const findings = [];
  const add = (severity, id, message, at) => findings.push({ severity, id, message, at });
  checkDocPaths(root, config, add);
  checkBanned(root, config, add);
  checkPlaceholders(root, config, add);
  checkSecrets(root, add);
  checkWorkflows(root, add);
  checkEntryFile(root, add);
  return findings;
}

function arg(argv, name, fallback) {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : fallback;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const root = resolve(arg(argv, '--root', '.'));
  const configPath = resolve(root, arg(argv, '--config', 'tools/checks/drift-config.json'));
  if (!existsSync(configPath)) { console.error(`config not found: ${configPath}`); process.exit(2); }
  const findings = runDrift(root, JSON.parse(readFileSync(configPath, 'utf8')));
  for (const f of findings) console.log(`${f.severity} [${f.id}] ${f.message}  at ${f.at}`);
  const errors = findings.filter((f) => f.severity === 'error').length;
  const warnings = findings.length - errors;
  console.log(`drift: ${errors} errors, ${warnings} warnings`);
  process.exit(errors || (warnings && argv.includes('--strict')) ? 1 : 0);
}
