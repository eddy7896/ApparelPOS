# Module: auth and roles
Status: Plan, nothing built (2026-11-17)

Purpose: lock screen, PINs, passwords, roles and idle lock.

- **Asked by owner:** cashier PIN of at least 6 digits with Argon2id; owner has full access.
- **Rules:** SSOT 1-4; ADR-0002, ADR-0003; guardrails 3, 5, 6.
- **Workflow:** the app opens on a lock screen; PIN opens Sales Mode, password opens Manager Mode; idle timeout locks; Ctrl+L locks manually.
- **Tasks:** P1-4, P2-2, P3-1.
- **Evals first:** E-AUTH-1, E-AUTH-2, E-AUTHZ-1, E-AUTHZ-2, E-ENC-1.
- **Not in scope:** cloud sign-in (release 2).
- **Open decisions:** lockout delay length (default decided at build).
