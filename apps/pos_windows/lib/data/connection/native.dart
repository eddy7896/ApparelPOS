import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_database.dart';
import '../encryption/encrypted_connection.dart';
import '../backup/backup_service.dart';
import '../backup/native_backup_controller.dart';
import '../encryption/key_store.dart';

/// The key store the running app uses: the Windows credential store.
final SecureKeyStore _secureKeys = SecureKeyStore();
KeyStore? get appKeyStore => _secureKeys;

/// Opens (or creates) `apparel_pos.db` in the app's own data folder, encrypted
/// with SQLCipher (E-ENC-1). The key is made on first launch and kept in the
/// operating system's credential store; see encrypted_connection.dart.
Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, 'apparel_pos.db'));
  return AppDatabase(await openEncryptedDatabase(file, _secureKeys));
}

/// The backup controller for the running app: backs up and restores the file
/// opened by [openAppDatabase].
Future<BackupController?> openBackupController(
  AppDatabase db,
  String Function() newId,
) async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'apparel_pos.db'));
  return NativeBackupController(
    db,
    file,
    _secureKeys,
    BackupService(db, file, _secureKeys, newId: newId),
  );
}
