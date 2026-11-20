# ADR-0016: Browser build as a development preview

- **Status:** Accepted (2026-11-20, owner)
- **Origin:** Requested by the owner (no Windows machine on hand); scope and limits proposed by the assistant
- **Builds on:** ADR-0004

## Context
The owner has no Windows computer to develop on. Flutter can run the same app in a browser, so screens can be built and looked at on a Mac. ADR-0004 rejected a web POS for the shop because offline hardware access is harder; that does not change.

## Decision
1. `apps/pos_windows` also has a `web` target, used **only** to build and look at screens during development. The shop runs the Windows app.
2. The web build is never used with real shop data and never deployed for the shop. It shows a "development only" line on screen.
3. Business rules stay in `core_domain` (pure Dart, so it runs on both). No rule is written in the app that only works on one platform.
4. Anything that exists only on Windows (SQLCipher encryption, the Windows credential store, USB or printer access, backups to USB, the installer) sits behind an interface in the app, with a stand-in for the browser. A stand-in must never claim to be encrypted.
5. A passing web build proves screens and logic work. It does **not** verify encryption (E-ENC-1), offline behaviour on the laptop, printing, scanning or backups; those are checked only on Windows (CI build now, a real machine before go-live).
6. CI builds the web target (`flutter build web`) next to the Windows build.

## Alternatives considered
- **macOS desktop target:** closer to a desktop app, but still not Windows; the owner asked for web.
- **Windows virtual machine only:** needs a Windows licence and setup; kept as an option for hardware tests.
- **Production web app:** rejected in ADR-0004; unchanged.

## Consequences
- Screens can be checked in a browser while Windows is checked by CI.
- Risk: code that works in the browser may fail on Windows (files, database, printing). Rule 4 and the CI Windows job reduce this; a real Windows run is still required before go-live.
- The folder is still called `pos_windows`; renaming is not worth the churn now.

## Enforcement
| Rule | Check |
|---|---|
| Web build compiles | CI job `dart-flutter-windows` step `pos_windows build (web)` |
| Web is not used for the shop | this ADR; on-screen notice |
| Windows build still compiles | CI Windows build step |

## Update 2026-11-20 (P2-2)
The browser build now opens a real SQLite database in memory using `apps/pos_windows/web/sqlite3.wasm`, the WebAssembly build from the sqlite3.dart release `sqlite3-3.9.1` (the version locked in `pubspec.lock`), downloaded from github.com/simolus3/sqlite3.dart/releases and checked against the sha256 GitHub lists for it (e7451780e78c56ff864fe9317a0fbcd6aeb2e8de3beba7f5efd963202f7ec3d9). It is a third-party binary kept in the repository; replace it when the sqlite3 package is upgraded. The data starts fresh on every reload. Debug builds offer practice users with fixed, published practice credentials; they are not available in release builds.

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D16 (built in P2-2) | Which browser database stand-in for development | in-memory / Drift on web | **Resolved 2026-11-20 (owner): no data kept between reloads; the browser build starts fresh. Nothing in the browser build opens a database yet.** |
