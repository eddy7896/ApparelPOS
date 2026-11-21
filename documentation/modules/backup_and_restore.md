# Module: backup and restore
Status: backup rules built in `core_domain` (P3-2a, 2026-11-21); the backup service, restore and screens are not built

Purpose: a daily copy of the encrypted database to two places, and a tested way back to a clean machine.

- **Asked by owner:** no lost sales data (biggest fear, ADR-0015).
- **Rules:** SSOT 20; ADR-0015; ADR-0003 points 7 to 11 (the backup is the encrypted file, so a restore needs the key or the recovery key).
- **Owner decisions (2026-11-21):** a backup is made when the last open shift of the day is closed, and again when the app starts if none was made today (India day); the owner picks the USB drive and a second folder with a folder picker in Manager Mode (needs one more package, `file_selector`); the last 60 backups are kept in each place, older ones deleted automatically (never the newest). Earlier: both a USB drive and a folder (ADR-0015, D6).
- **Rules built (P3-2a):** `BackupName` (`apparel-pos-YYYYMMDD-HHMMSS.backup`, India time, sorts in time order; anything else is not a backup name), `backupsToDelete` (oldest beyond the limit, ignores files that are not ours, never deletes the newest), `isBackupDue` (none made on today's India day; a backup dated after now does not block), `backupAfterClose` (only when no shift is left open).
- **Plan:** P3-2b backup service (consistent snapshot of the encrypted file, copy to both places, check each copy opens, prune, record last backup and any failure, restore into a clean place) with the E-BACKUP-1 restore test on a clean directory and an empty key store using the recovery key; P3-2c screens (folder pickers, Back up now, last backup and failures shown to the manager only, restore, automatic backup at shift close and at start-up).
- **Not in scope yet:** upload to the cloud (comes with sync, release 2).
- **Evals first:** E-BACKUP-1.
- **Open decisions:** none.
