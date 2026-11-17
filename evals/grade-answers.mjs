#!/usr/bin/env node
// Golden-set grader: section "The golden set" of 04-guardrails-and-hallucination-checks.md. Zero dependencies.
// Usage: node evals/grade-answers.mjs evals/hallucination-golden.json answers.json
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function grade(golden, answers) {
  const results = golden.items.map((item) => {
    const raw = answers[item.id];
    const text = typeof raw === 'string' ? raw.toLowerCase() : '';
    const reasons = [];
    if (!text) reasons.push('no answer');
    for (const group of item.mustInclude || []) {
      if (!group.some((s) => text.includes(s.toLowerCase()))) reasons.push(`missing one of: ${group.join(' | ')}`);
    }
    for (const s of item.mustNotInclude || []) {
      if (text.includes(s.toLowerCase())) reasons.push(`must not include: ${s}`);
    }
    return { id: item.id, severity: item.severity, pass: reasons.length === 0, reasons };
  });
  const passed = results.filter((r) => r.pass).length;
  const score = results.length ? passed / results.length : 0;
  const criticalFailures = results.filter((r) => !r.pass && r.severity === 'critical').map((r) => r.id);
  const threshold = golden.passThreshold ?? 0.95;
  return { results, score, threshold, criticalFailures, ok: results.length > 0 && score >= threshold && criticalFailures.length === 0 };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [goldenPath, answersPath] = process.argv.slice(2);
  if (!goldenPath || !answersPath) { console.error('usage: grade-answers.mjs <golden.json> <answers.json>'); process.exit(2); }
  const report = grade(JSON.parse(readFileSync(goldenPath, 'utf8')), JSON.parse(readFileSync(answersPath, 'utf8')));
  for (const r of report.results) console.log(`${r.pass ? 'pass' : 'FAIL'} ${r.id}${r.reasons.length ? `: ${r.reasons.join('; ')}` : ''}`);
  console.log(`score: ${(report.score * 100).toFixed(1)}% (threshold ${(report.threshold * 100).toFixed(0)}%)`);
  console.log(`critical failures: ${report.criticalFailures.join(', ') || 'none'}`);
  process.exit(report.ok ? 0 : 1);
}
