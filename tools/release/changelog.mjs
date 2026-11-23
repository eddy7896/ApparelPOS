#!/usr/bin/env node
// Reads CHANGELOG.md (Keep a Changelog style): finds the notes for one version,
// says whether a version is a pre-release, and checks the app's version has an
// entry. Used by the release workflow and by CI. Zero dependencies.
//
// Usage:
//   node tools/release/changelog.mjs --notes 0.9.0       prints the notes of that version
//   node tools/release/changelog.mjs --prerelease 0.9.0  prints true or false
//   node tools/release/changelog.mjs --check             the pubspec version has a dated entry
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HEADING = /^## \[([^\]]+)\](?:\s*-\s*(\d{4}-\d{2}-\d{2}))?\s*$/;

/** The sections of a changelog: [{ version, date, body }] in file order. */
export function parseChangelog(text) {
  const sections = [];
  let current = null;
  for (const line of text.split(/\r?\n/)) {
    const m = HEADING.exec(line);
    if (m) {
      current = { version: m[1], date: m[2] ?? null, lines: [] };
      sections.push(current);
    } else if (current && !/^\[[^\]]+\]:\s/.test(line)) {
      current.lines.push(line);
    }
  }
  return sections.map((s) => ({ version: s.version, date: s.date, body: s.lines.join('\n').trim() }));
}

/** The notes of [version]. Throws if there is no such entry, it has no date, or it is empty. */
export function extractNotes(text, version) {
  const s = parseChangelog(text).find((x) => x.version === version);
  if (!s) throw new Error(`CHANGELOG.md has no entry for version ${version}`);
  if (!s.date) throw new Error(`The CHANGELOG.md entry for ${version} has no date (expected "## [${version}] - YYYY-MM-DD")`);
  if (!s.body) throw new Error(`The CHANGELOG.md entry for ${version} is empty`);
  return s.body;
}

/** True for versions below 1.0.0 and for anything with a "-" suffix (0.9.0, 1.0.0-rc.1). */
export function isPrerelease(version) {
  if (!/^\d+\.\d+\.\d+([-+].+)?$/.test(version)) throw new Error(`Not a version: ${version}`);
  return Number(version.split('.')[0]) < 1 || version.includes('-');
}

/** The app version in a pubspec.yaml text, without the +build part. */
export function pubspecVersion(text) {
  const m = /^version:\s*(\d+\.\d+\.\d+)(?:\+\d+)?\s*$/m.exec(text);
  if (!m) throw new Error('No version: x.y.z in pubspec.yaml');
  return m[1];
}

/** Problems with a changelog text for the app version; empty list means fine. */
export function checkChangelog(changelogText, appVersion) {
  const errors = [];
  const sections = parseChangelog(changelogText);
  if (!sections.some((s) => s.version === 'Unreleased')) errors.push('CHANGELOG.md has no "## [Unreleased]" section');
  try {
    extractNotes(changelogText, appVersion);
  } catch (e) {
    errors.push(e.message);
  }
  return errors;
}

function main() {
  const args = process.argv.slice(2);
  const root = resolve(fileURLToPath(new URL('../..', import.meta.url)));
  const changelog = () => readFileSync(resolve(root, 'CHANGELOG.md'), 'utf8');
  try {
    if (args[0] === '--notes') {
      process.stdout.write(extractNotes(changelog(), args[1]) + '\n');
    } else if (args[0] === '--prerelease') {
      process.stdout.write(String(isPrerelease(args[1])) + '\n');
    } else if (args[0] === '--check') {
      const v = pubspecVersion(readFileSync(resolve(root, 'apps/pos_windows/pubspec.yaml'), 'utf8'));
      const errors = checkChangelog(changelog(), v);
      for (const e of errors) console.error(`error: ${e}`);
      console.log(`changelog: version ${v}, ${errors.length} errors`);
      process.exit(errors.length === 0 ? 0 : 1);
    } else {
      console.error('Usage: changelog.mjs --notes <version> | --prerelease <version> | --check');
      process.exit(2);
    }
  } catch (e) {
    console.error(`error: ${e.message}`);
    process.exit(1);
  }
}

// pathToFileURL, not a hand-made file:// string: on Windows the path is D:\a\... and
// only pathToFileURL turns it into the same URL as import.meta.url.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
