/// Business rules for the Apparel PoS. No Flutter, no database, no network.
/// Money is integer paise; there is no `double` in money code (E-MONEY-1).
library;

export 'src/barcode.dart';
export 'src/money.dart';
export 'src/permissions.dart';
export 'src/pricing.dart';

/// Version marker so the skeleton has something to test. Real rules start in P1-1.
const String coreDomainSkeletonVersion = '0.0.1';
