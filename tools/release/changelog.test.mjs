import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { test } from 'node:test';
import { checkChangelog, extractNotes, isPrerelease, parseChangelog, pubspecVersion } from './changelog.mjs';

const sample = `# Changelog

Some intro.

## [Unreleased]

### Added
- Something coming.

## [0.9.0] - 2026-11-22

### Added
- First thing (#1)
- Second thing (#2)

### Known limitations
- Not run on Windows.

## [0.8.0] - 2026-10-01

- Older.

[Unreleased]: https://example.org/compare/v0.9.0...HEAD
[0.9.0]: https://example.org/releases/tag/v0.9.0
`;

test('finds every section with its date', () => {
  const s = parseChangelog(sample);
  assert.deepEqual(s.map((x) => [x.version, x.date]), [['Unreleased', null], ['0.9.0', '2026-11-22'], ['0.8.0', '2026-10-01']]);
});

test('the notes of a version are its section only, without the link lines', () => {
  const n = extractNotes(sample, '0.9.0');
  assert.match(n, /^### Added/);
  assert.match(n, /Second thing \(#2\)/);
  assert.match(n, /Known limitations/);
  assert.doesNotMatch(n, /Older/);
  assert.doesNotMatch(n, /Something coming/);
  assert.doesNotMatch(n, /example\.org/);
});

test('a missing, undated or empty entry is an error', () => {
  assert.throws(() => extractNotes(sample, '9.9.9'), /no entry for version 9.9.9/);
  assert.throws(() => extractNotes(sample, 'Unreleased'), /no date/);
  assert.throws(() => extractNotes('## [1.0.0] - 2026-01-01\n\n## [0.9.0] - 2025-12-01\n- x', '1.0.0'), /is empty/);
});

test('pre-release: below 1.0.0 or with a suffix', () => {
  assert.equal(isPrerelease('0.9.0'), true);
  assert.equal(isPrerelease('0.0.1'), true);
  assert.equal(isPrerelease('1.0.0'), false);
  assert.equal(isPrerelease('2.3.4'), false);
  assert.equal(isPrerelease('1.0.0-rc.1'), true);
  assert.throws(() => isPrerelease('v1.0.0'), /Not a version/);
  assert.throws(() => isPrerelease('1.0'), /Not a version/);
});

test('reads the version from a pubspec, without the build number', () => {
  assert.equal(pubspecVersion('name: x\nversion: 0.9.0+1\n'), '0.9.0');
  assert.equal(pubspecVersion('version: 1.2.3\n'), '1.2.3');
  assert.throws(() => pubspecVersion('name: x\n'), /No version/);
});

test('the check wants an Unreleased section and a dated entry for the app version', () => {
  assert.deepEqual(checkChangelog(sample, '0.9.0'), []);
  assert.match(checkChangelog(sample, '0.10.0')[0], /no entry for version 0.10.0/);
  assert.match(checkChangelog(sample.replace('## [Unreleased]', '## [Next]'), '0.9.0')[0], /Unreleased/);
});

test('the real CHANGELOG.md has an entry for the real app version', () => {
  const root = new URL('../../', import.meta.url);
  const changelog = readFileSync(new URL('CHANGELOG.md', root), 'utf8');
  const version = pubspecVersion(readFileSync(new URL('apps/pos_windows/pubspec.yaml', root), 'utf8'));
  assert.deepEqual(checkChangelog(changelog, version), []);
});

test('run as a script it prints what the release workflow reads (notes and the prerelease flag)', () => {
  const script = new URL('./changelog.mjs', import.meta.url).pathname;
  const out = (...args) => execFileSync(process.execPath, [script, ...args], { encoding: 'utf8' });
  assert.equal(out('--prerelease', '0.9.0').trim(), 'true');
  assert.match(out('--notes', '0.9.0'), /Windows/);
});

test('1.0.0 is a full release, not a pre-release, and has notes', () => {
  const script = new URL('./changelog.mjs', import.meta.url).pathname;
  const out = (...args) => execFileSync(process.execPath, [script, ...args], { encoding: 'utf8' });
  assert.equal(out('--prerelease', '1.0.0').trim(), 'false');
  assert.match(out('--notes', '1.0.0'), /Release 1/);
});
