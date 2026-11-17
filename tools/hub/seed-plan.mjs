#!/usr/bin/env node
// Seeds hub plan data from the task tables: section 10 of 10-hub-data-model.md. Zero dependencies.
// Usage: node tools/hub/seed-plan.mjs --out hub/data/plan.json documentation/implementation_plan.md documentation/phase1_plan.md
// Tasks already in the output file are left untouched, so running it again adds new tasks and never resets progress.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const STATUSES = new Set(['todo', 'doing', 'done', 'blocked', 'waived']);
const cells = (line) => line.trim().replace(/^\||\|$/g, '').split(/(?<!\\)\|/).map((c) => c.trim());

export function parseTasks(markdown, source = 'input') {
  const tasks = [];
  const lines = markdown.split('\n');
  for (let i = 0; i < lines.length - 1; i++) {
    if (!lines[i].trim().startsWith('|') || !/^\s*\|[\s:|-]+\|\s*$/.test(lines[i + 1])) continue;
    const header = cells(lines[i]).map((h) => h.toLowerCase());
    const col = (n) => header.indexOf(n);
    if (['id', 'task', 'size', 'acceptance', 'status'].some((n) => col(n) < 0)) continue;
    for (let j = i + 2; j < lines.length && lines[j].trim().startsWith('|'); j++) {
      const row = cells(lines[j]);
      const id = row[col('id')];
      const phase = id.match(/^P(\d+)-\d+[a-z]?$/);
      if (!phase) throw new Error(`${source}: bad task ID: ${id}`);
      const status = row[col('status')].toLowerCase();
      if (!STATUSES.has(status)) throw new Error(`${source}: ${id} has unknown status: ${row[col('status')]}`);
      tasks.push({ id, name: row[col('task')], phase: Number(phase[1]), status });
    }
    i += 1;
  }
  return tasks;
}

export function seed(tasks, existing = { items: [] }, now = new Date().toISOString()) {
  const seen = new Set();
  for (const t of tasks) {
    if (seen.has(t.id)) throw new Error(`duplicate task ID: ${t.id}`);
    seen.add(t.id);
  }
  const items = [...existing.items];
  const have = new Set(items.map((t) => t.id));
  let order = items.reduce((m, t) => Math.max(m, t.order || 0), 0);
  for (const t of tasks) {
    if (have.has(t.id)) continue;
    order += 1;
    items.push({ id: t.id, name: t.name, phase: t.phase, phaseName: `Phase ${t.phase}`, milestone: '', order, status: t.status, pct: t.status === 'done' ? 100 : 0, pr: '', adr: '', owner: '' });
  }
  return { updatedAt: now, items };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const at = argv.indexOf('--out');
  if (at < 0 || !argv[at + 1]) { console.error('usage: seed-plan.mjs --out <plan.json> <plan.md>...'); process.exit(2); }
  const out = argv[at + 1];
  const inputs = argv.filter((_, i) => i !== at && i !== at + 1);
  try {
    const tasks = inputs.flatMap((f) => parseTasks(readFileSync(f, 'utf8'), f));
    const existing = existsSync(out) ? JSON.parse(readFileSync(out, 'utf8')) : { items: [] };
    const plan = seed(tasks, existing);
    writeFileSync(out, JSON.stringify(plan, null, 2) + '\n');
    console.log(`seed-plan: ${plan.items.length - existing.items.length} added, ${existing.items.length} kept`);
  } catch (e) {
    console.error(`seed-plan: ${e.message}`);
    process.exit(1);
  }
}
