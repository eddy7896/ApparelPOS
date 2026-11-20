import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_database.dart';

/// Opens (or creates) `apparel_pos.db` in the app's own data folder.
Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  return AppDatabase(
    NativeDatabase.createInBackground(File(p.join(dir.path, 'apparel_pos.db'))),
  );
}
