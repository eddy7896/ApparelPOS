import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'app/app.dart';
import 'app/brand_controller.dart';
import 'app/label_printer.dart';
import 'app/services.dart';
import 'app/session_controller.dart';
import 'app/startup_failed.dart';
import 'data/auth_service.dart';
import 'data/brand_repository.dart';
import 'data/connection/connection.dart';
import 'data/recovery_key_repository.dart';
import 'data/report_repository.dart';
import 'data/returns_repository.dart';
import 'data/sales_repository.dart';
import 'data/shift_repository.dart';
import 'data/demo_stock.dart';
import 'data/stock_lookup_repository.dart';
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
  String newId() => const Uuid().v4();
  final db = await openAppDatabase();
  final auth = AuthService(db, newId: newId);
  final stock = StockRepository(db, newId: newId);
  final sales = SalesRepository(db, newId: newId);
  final returns = ReturnsRepository(db, newId: newId);
  final shifts = ShiftRepository(db, newId: newId);
  final backup = await openBackupController(db, newId);
  final brand = BrandController(BrandRepository(db, newId: newId));
  await stock.ensureCounter();
  await brand.reload();
  final session = SessionController(
    auth: auth,
    onPracticeUsers: () => seedDemoStock(db, stock),
  );
  runApp(
    PosApp(
      session: session,
      services: AppServices(
        stock: stock,
        sales: sales,
        returns: returns,
        shifts: shifts,
        reports: ReportRepository(db),
        stockLookup: StockLookupRepository(db),
        recovery: appKeyStore == null
            ? null
            : RecoveryKeyRepository(db, appKeyStore!, newId: newId),
        backup: backup,
        brand: brand,
        auth: auth,
        printer: const SystemLabelPrinter(),
        fonts: loadBundledLabelFonts,
      ),
    ),
  );
  await session.start();
  // The start-up backup (if one is due and places are chosen); never throws.
  unawaited(backup?.backupIfDue());
}
