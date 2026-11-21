#!/usr/bin/env node
// Guards where the Windows app keeps the shop's data (ADR-0018, rule 5 of the
// runbook). The data folder comes from the exe's CompanyName and ProductName
// (path_provider_windows 2.3.0, checked in its source on 2026-11-21), and the
// installer's AppId lets a new Setup upgrade the old install in place. If any of
// them change by accident the app starts on an empty database. Zero dependencies.
// Usage: node tools/checks/data-location.mjs [--root .] [--config tools/checks/windows-identity.json]
import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

/** Pure check: returns { ok, errors[] } for the three file texts and the pinned identity. */
export function evaluate({ rcText, mainCppText, installerText, identity }) {
  const errors = [];
  const rcValue = (name) => {
    const m = new RegExp(`VALUE\\s+"${name}"\\s*,\\s*"([^"]*)"`).exec(rcText ?? '');
    return m ? m[1] : null;
  };
  const company = rcValue('CompanyName');
  const product = rcValue('ProductName');
  if (company !== identity.companyName) {
    errors.push(`Runner.rc CompanyName is ${JSON.stringify(company)}, expected ${JSON.stringify(identity.companyName)}: this moves the shop's data folder`);
  }
  if (product !== identity.productName) {
    errors.push(`Runner.rc ProductName is ${JSON.stringify(product)}, expected ${JSON.stringify(identity.productName)}: this moves the shop's data folder`);
  }
  const title = /window\.Create\(L"([^"]*)"/.exec(mainCppText ?? '');
  if (!title || title[1] !== identity.windowTitle) {
    errors.push(`main.cpp window title is ${JSON.stringify(title?.[1] ?? null)}, expected ${JSON.stringify(identity.windowTitle)}`);
  }
  const appId = /^AppId=(.+)$/m.exec(installerText ?? '');
  if (!appId || appId[1].trim() !== identity.installerAppId) {
    errors.push(`installer AppId is ${JSON.stringify(appId?.[1]?.trim() ?? null)}, expected ${JSON.stringify(identity.installerAppId)}: a changed AppId stops Setup upgrading in place`);
  }
  return { ok: errors.length === 0, errors };
}

function main() {
  const args = process.argv.slice(2);
  const arg = (name, fallback) => {
    const i = args.indexOf(name);
    return i >= 0 ? args[i + 1] : fallback;
  };
  const root = resolve(arg('--root', '.'));
  const configPath = resolve(root, arg('--config', 'tools/checks/windows-identity.json'));
  const identity = JSON.parse(readFileSync(configPath, 'utf8'));
  const read = (rel) => (existsSync(join(root, rel)) ? readFileSync(join(root, rel), 'utf8') : null);
  const result = evaluate({
    rcText: read(identity.rc),
    mainCppText: read(identity.mainCpp),
    installerText: read(identity.installerScript),
    identity,
  });
  for (const e of result.errors) console.error(`error: ${e}`);
  console.log(`data-location: ${result.errors.length} errors`);
  process.exit(result.ok ? 0 : 1);
}

if (import.meta.url === `file://${process.argv[1]}`) main();
