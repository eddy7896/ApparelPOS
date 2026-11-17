# System memory
Status: 2026-11-17

Purpose: decisions in brief and lessons learned, newest first.

- 2026-11-18: Barcode is 12 digits (check digit added, owner-approved; Luhn is the assistant's pick). Counters are separated by lot-number ranges. Golden question G-09 updated to match.
- 2026-11-18: Rounding is half up (owner). Negative amounts round symmetrically (assistant's reading; unconfirmed) so returns reverse sales exactly. Percentages are basis points. Money type lives in `core_domain` (P1-1).
- 2026-11-18: Gate 5 passed; bootstrap complete. Owner chose separate Dart/Flutter folders (no pub workspace); ADR-0004 allows Melos or workspace, so this is a small deviation to confirm in the ADR. Flutter and Dart are installed on the Mac; Windows build unverified.
- 2026-11-17: Gate 2 passed. Counters keep their own databases and sync through the cloud (ADR-0008). Cashier PIN is 6+ digits with Argon2id (ADR-0002). Database is encrypted (ADR-0003). GST is off by default; the owner chooses inclusive/exclusive, rate and rounding at setup (ADR-0007). Backups go to USB and a folder (ADR-0015).
- 2026-11-17: Gate 1 passed. Project Brief confirmed (`project_brief.md`).
- 2026-11-17: The gate guard rejected a state update when the owner's message was not a plain "proceed"; always wait for the explicit word.
