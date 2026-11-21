/// Business rules for the Apparel PoS. No Flutter, no database, no network.
/// Money is integer paise; there is no `double` in money code (E-MONEY-1).
library;

export 'src/article_status.dart';
export 'src/auth_rules.dart';
export 'src/barcode.dart';
export 'src/bill_number.dart';
export 'src/code128.dart';
export 'src/credit_note.dart';
export 'src/hangtag_artwork.dart';
export 'src/label_layout.dart';
export 'src/money.dart';
export 'src/payment.dart';
export 'src/permissions.dart';
export 'src/pricing.dart';
export 'src/purchase.dart';
export 'src/report_rules.dart';
export 'src/return_rules.dart';
export 'src/shift_rules.dart';
export 'src/shop_time.dart';

/// Version marker so the skeleton has something to test. Real rules start in P1-1.
const String coreDomainSkeletonVersion = '0.0.1';
