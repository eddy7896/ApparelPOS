import '../data/auth_service.dart';
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
    required this.auth,
    required this.printer,
    required this.fonts,
  });

  final StockRepository stock;
  final SalesRepository sales;
  final ReturnsRepository returns;
  final ShiftRepository shifts;

  /// Used by the register to check a manager's password for a big discount.
  final AuthService auth;
  final LabelPrinter printer;
  final Future<LabelFonts> Function() fonts;
}
