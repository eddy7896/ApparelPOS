import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;

import '../data/auth_service.dart';
import '../data/brand.dart';
import '../data/backup/backup_models.dart';
import '../data/recovery_key_repository.dart';
import '../data/report_repository.dart';
import '../data/returns_repository.dart';
import '../data/sales_repository.dart';
import '../data/shift_repository.dart';
import '../data/stock_repository.dart';
import 'brand_controller.dart';
import 'label_printer.dart';
import 'pickers.dart';

/// What the screens need besides who is signed in.
class AppServices {
  const AppServices({
    required this.stock,
    required this.sales,
    required this.returns,
    required this.shifts,
    required this.reports,
    required this.auth,
    required this.printer,
    this.recovery,
    this.brand,
    this.brandPreview = kDebugMode,
    this.backup,
    this.pickers = const FilePickers(),
    required this.fonts,
  });

  final StockRepository stock;
  final SalesRepository sales;
  final ReturnsRepository returns;
  final ShiftRepository shifts;
  final ReportRepository reports;

  /// Used by the register to check a manager's password for a big discount.
  final AuthService auth;

  /// The recovery key (null in the browser preview, which has no encryption).
  final RecoveryKeyRepository? recovery;

  /// The shop's current look (null in tests that do not care: the placeholder).
  final BrandController? brand;

  /// Shows the development-only button to try a look in Manager Mode. There is
  /// no shop-facing settings screen until the owner's mobile app (Release 2).
  final bool brandPreview;

  /// The look to show now: the shop's, or the placeholder.
  Brand get currentBrand => brand?.brand ?? Brand.placeholder;

  /// Backing up and restoring (null in the browser preview).
  final BackupController? backup;

  /// The folder and file dialogs.
  final FilePickers pickers;
  final LabelPrinter printer;
  final Future<LabelFonts> Function() fonts;

  /// After a shift is closed: if no shift is left open, back up (in the
  /// background; a failure is recorded for the manager and never shown here).
  void backupAfterShiftClose() {
    final controller = backup;
    if (controller == null) {
      return;
    }
    unawaited(() async {
      try {
        await controller.backupAfterShiftClose(
          openShiftsLeft: await shifts.openShiftCount(),
        );
      } on Object {
        // recorded by the backup service; billing must carry on
      }
    }());
  }
}
