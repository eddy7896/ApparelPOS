import '../data/auth_service.dart';
import '../data/sales_repository.dart';
import '../data/stock_repository.dart';
import 'label_printer.dart';

/// What the screens need besides who is signed in.
class AppServices {
  const AppServices({
    required this.stock,
    required this.sales,
    required this.auth,
    required this.printer,
    required this.fonts,
  });

  final StockRepository stock;
  final SalesRepository sales;

  /// Used by the register to check a manager's password for a big discount.
  final AuthService auth;
  final LabelPrinter printer;
  final Future<LabelFonts> Function() fonts;
}
