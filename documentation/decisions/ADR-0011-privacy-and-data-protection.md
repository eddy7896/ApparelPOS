# ADR-0011: Privacy and data protection

- **Status:** Accepted (2026-11-17, owner)
- **Origin:** Proposed by the assistant

## Context
Customer name and phone are optional at checkout. The shop is in India. **Every legal point here is unverified until counsel confirms.**

## Decision
1. Customer phone and name are optional and off by default; the bill works without them.
2. They are used only for the stated purpose (receipts, returns lookup) and shown to the cashier only as needed.
3. Customer data is excluded from analytics summaries sent to the cloud unless needed.
4. The owner can delete a customer's record on request.
5. A short privacy notice is shown at the counter (wording needs counsel).

## Alternatives considered
- **Mandatory phone number:** more personal data than needed.

## Consequences
- Loyalty (out of scope) would need a new consent decision.

## Enforcement
| Rule | Check |
|---|---|
| Bill works with no customer | test (planned) |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D5 | Applicable data-protection obligations | per counsel | Ask counsel |
