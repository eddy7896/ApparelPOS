# Phase 0 gate: Gate 4 (checks green)
Status: ready for owner review, 2026-11-17

Purpose: evidence that the documentation checks exist, can fail, and pass.

## What was run
| Command | Result |
|---|---|
| `npm run check:drift` | 0 errors, 0 warnings (an earlier run found 3 real errors: documents named `drift.mjs`, the file is `drift-check.mjs`; fixed) |
| `npm run check:project-rules` | 0 errors on the repository |
| `npm run eval:hallucination` | 100.0% on 40 ideal answers, no critical failures |
| `npm run test:checks` | 23 tests pass, 0 fail |
| Grader fed a wrong answer | 0.0%, critical failures listed (proves it can fail) |
| Project rules fed `double totalAmount` | 1 error, exit 1 (proves it can fail) |

Node v22.23.4. The workspace is not a git repository, so `git ls-files` was not used; the scripts fall back to walking files.

## Criteria
| ID | Criterion | Proven by |
|---|---|---|
| E-MONEY-1 (check only) | No `double` or `num` money field in Dart code | `tools/checks/project-rules.test.mjs` |
| ADR-0004 | Only `sync_engine` imports Firestore | `tools/checks/project-rules.test.mjs` |
| Drift 1 to 6 | Paths, banned dependencies, placeholders, secrets, workflows, entry-file commands | `tools/checks/scripts.test.mjs` |
| E-HAL | Golden set grades correctly | `scripts.test.mjs` grader tests and the run above |

## What the system does now
Documents and checks only. No application code exists.

## Not proven
- Every other eval in `eval_plan.md` (E-AUTH, E-AUTHZ, E-ENC, E-SERIAL, E-SALE, E-RETURN, E-SHIFT, E-OFFLINE, E-BACKUP, E-PRIV, E-AUDIT, E-GST) needs Dart code and Flutter, which is not installed here (unverified). They are planned for P1 to P3.
- The golden set was graded against answers I wrote, not against a fresh agent session.
- CI does not exist yet (Gate 5), so none of these checks has run in CI.
- `workflow-valid` and the branch-policy check have no workflow files to examine yet.

## Owner actions outstanding
- Review ADR-0006, ADR-0013, ADR-0014 (still Proposed).
- Turn on GitHub branch protection (after Gate 5).

## Status
Closed for the mechanical checks that can exist before code. The remaining evals cannot close until Flutter is available and the code exists.
