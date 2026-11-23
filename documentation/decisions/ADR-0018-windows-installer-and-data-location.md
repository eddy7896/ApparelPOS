# ADR-0018: Windows installer and where the shop's data lives

- **Status:** Proposed (2026-11-21). The owner chose Inno Setup, unsigned for now, per-user, data kept on uninstall; everything else is the assistant's.
- **Origin:** Owner answers of 2026-11-21 (an MSIX request was dropped because an unsigned MSIX cannot be installed on a normal laptop; Inno Setup was chosen instead)
- **Builds on:** ADR-0003, ADR-0015, ADR-0016

## Context
The shop needs one file it can double-click to install the counter app, without an administrator password and without losing data on reinstall or upgrade. Windows keeps the data folder of a Flutter app by the exe's version-resource names, and the installer recognises an earlier install by its AppId, so both must stay fixed.

## Decision
1. The installer is a Setup `.exe` made with **Inno Setup 6** from `installer/apparel_pos.iss`. It installs **for the current Windows user only** (`PrivilegesRequired=lowest`, into `%LOCALAPPDATA%\Programs\Apparel PoS`), adds a Start menu entry and an optional desktop shortcut, and offers to open the app at the end.
2. **Unsigned for now (owner).** Windows is expected to show its "Windows protected your PC" (SmartScreen) warning once; the owner clicks "More info" then "Run anyway" (to be written in the runbook). Signing with a paid certificate can be added later without changing the app. *Unverified:* the exact wording and steps of the warning on the shop's Windows version.
3. **Removing the program keeps the data.** The database and its key live outside the install folder (the database in `%APPDATA%\Apparel PoS\Apparel PoS`, the key in the Windows credential store), so uninstalling and reinstalling, or installing a newer Setup over an older one, brings everything back. The uninstaller says so.
4. **The data folder is pinned.** `path_provider_windows` 2.3.0 (source read on 2026-11-21) keeps the data in `%APPDATA%\<CompanyName>\<ProductName>` taken from `apps/pos_windows/windows/runner/Runner.rc`. They are set to `Apparel PoS` and `Apparel PoS`, and the installer's `AppId` is fixed. `tools/checks/windows-identity.json` pins all of them and `npm run check:data-location` (run in CI) fails if any changes. To change one on purpose, change the JSON in the same pull request and write a data migration. This must be settled before go-live and never changed after.
5. The Visual C++ runtime DLLs (`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`) are copied next to the exe from the Windows runner's System32 at build time, so a clean laptop does not need the redistributable installed. *Unverified:* Microsoft's redistribution terms for this app-local copy; check before go-live.
6. The app version is `0.9.0` (release candidate) in `apps/pos_windows/pubspec.yaml`; Setup is named `ApparelPoS-Setup-<version>.exe`. The version moves to 1.0.0 when the owner has run the go-live checks.
7. CI (`dart-flutter-windows`) builds Setup on every pull request, installs it silently into a temp folder, checks the files are there, starts the app for 10 seconds and checks it did not stop, uninstalls it, and keeps Setup as a build artifact for 14 days (named `ApparelPoS-Setup`). Inno Setup comes from the runner image or from Chocolatey (a third-party download at build time). The artifact is for the owner to download; it is **not** a release.
8. The app icon is still Flutter's default and the publisher name is "Apparel PoS" (a placeholder). The owner can supply an icon (`apps/pos_windows/windows/runner/resources/app_icon.ico`) and a real shop or company name; changing the company name moves the data folder (point 4), so the name must be chosen before go-live.

## Alternatives considered
- **MSIX package:** needs a trusted signing certificate to install on a normal laptop; rejected for now (owner).
- **A zip folder:** no shortcuts or uninstaller; easy to lose; rejected.
- **Per-machine install (administrator password):** no benefit with one Windows login.

## Consequences
- The first real proof that the installed app starts is the CI smoke test; nobody has run it on a real shop laptop.
- Anyone who reinstalls Windows must restore from a backup with the recovery key (ADR-0003, ADR-0015); uninstalling alone does not lose data.

## Enforcement
| Rule | Check |
|---|---|
| Data folder names and installer AppId unchanged | `npm run check:data-location`, tests in `tools/checks/data-location.test.mjs` |
| Setup builds, installs, starts and uninstalls | CI job `dart-flutter-windows` (installer steps) |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D9 | Company or shop name for the Windows identity and publisher | any, before go-live | owner to choose |
| D10 | Code-signing certificate | buy later / now | later |
