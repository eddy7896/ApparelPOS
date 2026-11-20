import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'app/app.dart';
import 'app/session_controller.dart';
import 'data/auth_service.dart';
import 'data/connection/connection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final auth = AuthService(db, newId: () => const Uuid().v4());
  final session = SessionController(auth: auth);
  runApp(PosApp(session: session));
  await session.start();
}
