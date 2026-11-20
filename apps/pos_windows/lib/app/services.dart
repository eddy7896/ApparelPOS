import '../data/stock_repository.dart';
import 'label_printer.dart';

/// What the screens need besides who is signed in.
class AppServices {
  const AppServices({
    required this.stock,
    required this.printer,
    required this.fonts,
  });

  final StockRepository stock;
  final LabelPrinter printer;
  final Future<LabelFonts> Function() fonts;
}
