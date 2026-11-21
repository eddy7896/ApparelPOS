import '../data/auth_service.dart';
import '../data/recovery_key_repository.dart';
import '../data/report_repository.dart';
import '../data/returns_repository.dart';
import '../data/sales_repository.dart';
import '../data/shift_repository.dart';
import '../data/stock_repository.dart';
import 'label_printer.dart';

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
  final LabelPrinter printer;
  final Future<LabelFonts> Function() fonts;
}
