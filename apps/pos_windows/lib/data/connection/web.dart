import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

import '../app_database.dart';

/// Browser preview: an in-memory database that starts fresh on every reload.
/// `web/sqlite3.wasm` is SQLite 3.9.1's WebAssembly build from the sqlite3.dart
/// releases (sha256 e7451780...ec3d9), the version matching the locked package.
Future<AppDatabase> openAppDatabase() async {
  final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  // An in-memory database still needs a registered file system, or opening it
  // fails with "no such vfs" and the page stays blank.
  sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  return AppDatabase(WasmDatabase.inMemory(sqlite3));
}
