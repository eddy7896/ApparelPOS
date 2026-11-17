# ADR-0001: Single-store data isolation

- **Status:** Accepted (2026-11-17, owner)
- **Builds on:** ADR-0002, ADR-0003
- **Origin:** Proposed by the assistant

## Context
One client, one shop. Multi-shop is out of scope. The spec still namespaces cloud data under `stores/{storeId}`.

## Decision
1. All cloud data lives under one `stores/{storeId}` document tree; `storeId` comes from the verified auth token, never from a client request.
2. Firestore rules deny by default and allow only a signed-in user whose token `storeId` matches the path.
3. No cross-store features are built in release 1.

## Alternatives considered
- **No storeId at all:** cheaper now, but retrofitting a second shop later is costly.
- **One Firebase project per shop:** safest, but extra operations cost.

## Consequences
- Small cost now; a second shop later needs no migration.

## Enforcement
| Rule | Check |
|---|---|
| Rules deny by default, storeId from token | Firestore rules emulator test (planned) |

## Open decisions
None.
