// Several garments of one size and color on one bill. Each garment keeps its
// own barcode and is sold once (E-SALE-1), so "3 of these" means three
// different barcodes. This only chooses which ones; the register still checks
// every one with the usual sale rules.

const int maxGarmentsAtOnce = 50;

/// A quantity kept between 1 and [maxGarmentsAtOnce].
int clampGarmentCount(int n) => n < 1
    ? 1
    : n > maxGarmentsAtOnce
    ? maxGarmentsAtOnce
    : n;

/// Up to [count] barcodes from [candidates], lowest first, none already on the
/// bill, each once.
List<String> pickGarments(
  List<String> candidates,
  Set<String> onBill,
  int count,
) {
  if (count <= 0) {
    return const [];
  }
  final sorted = {...candidates}.where((c) => !onBill.contains(c)).toList()
    ..sort();
  return sorted.take(count).toList();
}
