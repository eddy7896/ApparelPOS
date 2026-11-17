# System memory
Status: 2026-11-17

Purpose: decisions in brief and lessons learned, newest first.

- 2026-11-17: Gate 2 passed. Counters keep their own databases and sync through the cloud (ADR-0008). Cashier PIN is 6+ digits with Argon2id (ADR-0002). Database is encrypted (ADR-0003). GST is off by default; the owner chooses inclusive/exclusive, rate and rounding at setup (ADR-0007). Backups go to USB and a folder (ADR-0015).
- 2026-11-17: Gate 1 passed. Project Brief confirmed (`project_brief.md`).
- 2026-11-17: The gate guard rejected a state update when the owner's message was not a plain "proceed"; always wait for the explicit word.
