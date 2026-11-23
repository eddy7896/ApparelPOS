# Release process
Status: built 2026-11-22 (P3-3c); the first release is 0.9.0, not yet made

Purpose: how a release of the Windows counter app is made, who does what, and what ends up on GitHub. A release is a **version tag** on `main`, and a **GitHub Release** with the installer attached, built by the release workflow. Branching is in ADR-0013 (the owner merges and releases).

## What a release contains
- `ApparelPoS-Setup-<version>.exe`: the installer (per-user, unsigned, ADR-0018).
- `ApparelPoS-<version>-windows-x64.zip`: the app folder without an installer (portable).
- `SHA256SUMS.txt`: the checksums of the two files.
- Release notes: the version's section of [CHANGELOG.md](../CHANGELOG.md), copied by the workflow.
- Marked **pre-release** while the version is below 1.0.0 or has a suffix such as `-rc.1`.

## Steps (owner, with the assistant's help)
1. **Decide the version** and set it in `apps/pos_windows/pubspec.yaml` (`version: 0.9.0+1`; the part before `+` is the release version). Move the finished items from `## [Unreleased]` to a new `## [x.y.z] - YYYY-MM-DD` section in `CHANGELOG.md`, update `documentation/feature_log.md`, and update the link lines at the bottom. `npm run check:changelog` (also run in CI) fails if the app's version has no dated entry.
2. **Open a release pull request** from `develop` to `main` (title `Release x.y.z`). CI must be green, including the Windows job, which builds and test-installs the installer on every pull request. The owner reviews and merges it.
3. **Tag the merge commit on `main`** and push the tag:
   ```
   git checkout main && git pull
   git tag -a v0.9.0 -m "Apparel PoS 0.9.0"
   git push origin v0.9.0
   ```
   (or create the tag in the GitHub web page: Releases, Draft a new release, choose the tag; do not attach files by hand.)
4. **The release workflow** (`.github/workflows/release.yml`) starts on the tag. It checks the tag is on `main`, that it matches the app's version and that the changelog has the entry; builds the Windows app; builds and test-installs the installer; and creates the GitHub Release with the files above.
5. **Check the release page**: open https://github.com/eddy7896/ApparelPOS/releases, download the Setup, compare its SHA-256 with `SHA256SUMS.txt`, install it on a spare Windows computer.
6. If something is wrong, do not edit the release: fix it on `develop`, make a new version (for example 0.9.1) and release that. A bad release can be deleted on GitHub (the tag with it) by the owner.

## Rules
- The release workflow runs only for tags named `vMAJOR.MINOR.PATCH` (optionally with a `-suffix`). It never runs for a branch.
- The tag must be on a commit that is on `main` (so it has passed the pull request checks and the owner's merge).
- The version is never reused: a new tag for each change.
- The workflow has write access to the repository's releases only; it uses GitHub's built-in token and no other secret. There is no code-signing certificate yet (ADR-0018 D10).
- Hotfixes follow ADR-0013 (`hotfix/<name>` to `main`, then back to `develop`) and are released the same way with a new patch version.

## Not verified
- The release workflow has not made a real release yet: its first run will be the 0.9.0 tag. It uses the same build and install steps that CI ran on pull request #33.
- Nobody has installed a released Setup on a real shop laptop.
