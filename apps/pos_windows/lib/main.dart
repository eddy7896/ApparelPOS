import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'app/app.dart';
import 'app/label_printer.dart';
import 'app/services.dart';
import 'app/startup_failed.dart';
import 'app/session_controller.dart';
import 'data/auth_service.dart';
import 'data/connection/connection.dart';
import 'data/returns_repository.dart';
import 'data/sales_repository.dart';
import 'data/shift_repository.dart';
import 'data/stock_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _start();
  } on Object catch (error) {
    // Show the problem instead of a blank window.
    runApp(StartupFailedApp(error: error));
  }
}

Future<void> _start() async {
  final db = await openAppDatabase();
  final auth = AuthService(db, newId: () => const Uuid().v4());
  final stock = StockRepository(db, newId: () => const Uuid().v4());
  final sales = SalesRepository(db, newId: () => const Uuid().v4());
  final returns = ReturnsRepository(db, newId: () => const Uuid().v4());
  final shifts = ShiftRepository(db, newId: () => const Uuid().v4());
  await stock.ensureCounter();
  final session = SessionController(auth: auth);
  runApp(
    PosApp(
      session: session,
      services: AppServices(
        stock: stock,
        sales: sales,
        returns: returns,
        shifts: shifts,
        auth: auth,
        printer: const SystemLabelPrinter(),
        fonts: loadBundledLabelFonts,
      ),
    ),
  );
  await session.start();
}
