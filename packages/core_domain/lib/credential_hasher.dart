/// Hashes PINs and passwords with Argon2id (E-AUTH-1, ADR-0002). A separate
/// entry point so the main `core_domain` library stays free of `hashlib`.
library;

export 'src/credential_hasher.dart';
