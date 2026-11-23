// Choosing a folder or a backup file. The app uses the operating system's own
// dialogs through `file_selector`; tests pass fakes.
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class FilePickers {
  const FilePickers({
    this.folder = _pickFolder,
    this.backupFile = _pickBackupFile,
    this.logoFile = _pickLogoFile,
  });

  /// Asks for a folder; null if cancelled.
  final Future<String?> Function() folder;

  /// Asks for a backup file; null if cancelled.
  final Future<String?> Function() backupFile;

  /// Asks for a logo picture and returns its bytes; null if cancelled.
  final Future<Uint8List?> Function() logoFile;
}

Future<String?> _pickFolder() =>
    getDirectoryPath(confirmButtonText: 'Choose this folder');

Future<String?> _pickBackupFile() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Apparel PoS backups', extensions: ['backup']),
    ],
    confirmButtonText: 'Restore this backup',
  );
  return file?.path;
}

Future<Uint8List?> _pickLogoFile() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Pictures', extensions: ['png', 'jpg', 'jpeg']),
    ],
    confirmButtonText: 'Use this logo',
  );
  return file?.readAsBytes();
}
