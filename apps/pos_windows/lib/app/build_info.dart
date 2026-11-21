import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the local database is encrypted with SQLCipher (E-ENC-1). True on
/// Windows and the other desktop builds, where the database file is encrypted
/// and the app refuses to start on a build without SQLCipher. False in the
/// browser preview, which keeps nothing and must never hold real shop data.
const bool databaseEncrypted = !kIsWeb;
