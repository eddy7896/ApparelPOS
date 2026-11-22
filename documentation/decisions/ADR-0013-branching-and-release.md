# ADR-0013: Branching, review and release

- **Status:** Proposed
- **Origin:** Proposed by the assistant; solo builder, repository https://github.com/eddy7896/ApparelPOS.git

## Context
One builder. The kit allows a simpler model for a small team (`06`).

## Decision
1. Branches: `main` (production, releases) and `develop` (integration). Topic branches `feat|fix|chore/<topic>` merge into `develop` by pull request; `develop` merges into `main` for a release; `hotfix/<name>` goes to `main`, then back into `develop`.
2. Nobody pushes directly to `main` or `develop`; no force-push on shared branches.
3. Every pull request uses the template and shows its evidence and what was not verified.
4. A branch-policy check and the full checks run in CI on every pull request.
5. The owner merges and releases; the agent opens pull requests only.
6. Commit messages use `type(scope): summary`. Commits made by the agent end with the attribution lines from the session.
7. **Releases (2026-11-22, P3-3c):** a release is a tag `vMAJOR.MINOR.PATCH` on `main`, made by the owner after merging a release pull request from `develop`; the tag starts `.github/workflows/release.yml`, which builds the Windows installer and creates the GitHub Release with the installer, a portable zip, `SHA256SUMS.txt` and the notes from `CHANGELOG.md` (a pre-release while below 1.0.0). Steps are in `documentation/release_process.md`. The agent prepares the changelog and the pull request and pushes a tag only when the owner asks for that release.

## Alternatives considered
- **App branches (`app/<name>`):** needless overhead for one builder.

## Consequences
- Owner must enable branch protection in GitHub (agents cannot). **Owner action.**

## Enforcement
| Rule | Check |
|---|---|
| Allowed branch edges | branch-policy check E-BRANCH-1..n (planned) |

## Open decisions
None.
