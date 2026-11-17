#!/usr/bin/env node
// Project rules (check 16 of 05-drift-evals-tests.md). Zero dependencies.
// Usage: node tools/checks/project-rules.mjs [--root .]
//  money-float      E-MONEY-1  guardrail 7, ADR-0007: no double/float/num money fields in Dart code
//  firestore-import ADR-0004   guardrail 9: only packages/sync_engine may import cloud_firestore
import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SKIP = new Set(['.git', 'node_modules', 'build', '.dart_tool']);
const MONEY = '(price|amount|total|mrp|tax|cost|balance|refund|paise|discount|gst)';
const FLOAT_MONEY = new RegExp(`\\b(double|num)\\??\\s+\\w*${MONEY}\\w*`, 'i');

function dartFiles(root, dir = root, out = []) {
  if (!existsSync(dir)) return out;
  for (const name of readdirSync(dir)) {
    if (SKIP.has(name)) continue;
    const full = join(dir, name);
    if (statSync(full).isDirectory()) dartFiles(root, full, out);
    else if (name.endsWith('.dart')) out.push(relative(root, full).split('\\').join('/'));
  }
  return out;
}

export function runProjectRules(root) {
  const findings = [];
  for (const file of dartFiles(root)) {
    const lines = readFileSync(join(root, file), 'utf8').split('\n');
    lines.forEach((line, i) => {
      if (/^\s*\/\//.test(line)) return;
      if (FLOAT_MONEY.test(line)) findings.push({ severity: 'error', id: 'money-float', message: `floating-point money on line ${i + 1} (E-MONEY-1)`, path: file });
      if (/cloud_firestore/.test(line) && /^\s*import\b/.test(line) && !file.startsWith('packages/sync_engine/')) {
        findings.push({ severity: 'error', id: 'firestore-import', message: `only packages/sync_engine may import cloud_firestore (line ${i + 1})`, path: file });
      }
    });
  }
  return findings;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const i = process.argv.indexOf('--root');
  const root = resolve(i >= 0 ? process.argv[i + 1] : '.');
  const findings = runProjectRules(root);
  for (const f of findings) console.log(`${f.severity} [${f.id}] ${f.message}  at ${f.path}`);
  console.log(`project-rules: ${findings.length} errors`);
  process.exit(findings.length ? 1 : 0);
}
