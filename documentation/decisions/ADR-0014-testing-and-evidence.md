# ADR-0014: Testing and evidence

- **Status:** Proposed
- **Origin:** Proposed by the assistant

## Context
Money and stock errors are costly. Many checks cannot run until Flutter is installed (unverified in this workspace).

## Decision
1. Pure rules in `core_domain` have unit tests and property tests (money, serial ranges, pricing).
2. Database tests run against a real SQLite file, including encryption and migrations.
3. Widget tests cover billing, returns and shift close.
4. Evals are written before the feature and shown failing first.
5. Each pull request reports commands run and results, and lists what was not verified.
6. Done means the checklist in `AGENTS.md` is satisfied.

## Alternatives considered
- **Tests after the feature:** misses the failing-first proof.

## Consequences
- Slower start; fewer money bugs.

## Enforcement
| Rule | Check |
|---|---|
| Evals exist and pass | CI (planned) |

## Open decisions
None.
