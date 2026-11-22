// How much is left of a size and color, in plain terms: out, low or fine. The
// owner can change the low-stock line later; 2 or fewer is the assistant's
// choice, to be confirmed (2026-11-22).

/// A size and color with this many or fewer (but not none) is low.
const int lowStockAtMost = 2;

enum StockLevel { out, low, ok }

/// None (or a bad negative count) is out; 1 up to [lowStockAtMost] is low.
StockLevel stockLevel(int inStock) {
  if (inStock <= 0) {
    return StockLevel.out;
  }
  return inStock <= lowStockAtMost ? StockLevel.low : StockLevel.ok;
}

/// What the stock lookup shows: everything, only what can be sold, only what
/// is out, or only what is running low.
enum StockFilter {
  all,
  inStock,
  outOfStock,
  low;

  /// True when a size and color with [inStock] garments passes this filter.
  bool keeps(int inStock) => switch (this) {
    StockFilter.all => true,
    StockFilter.inStock => inStock > 0,
    StockFilter.outOfStock => stockLevel(inStock) == StockLevel.out,
    StockFilter.low => stockLevel(inStock) == StockLevel.low,
  };
}
