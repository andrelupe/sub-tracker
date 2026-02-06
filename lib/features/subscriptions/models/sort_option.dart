/// Sort options for the subscription list.
enum SortOption {
  nextBillingDate('Next Billing', true),
  name('Name', true),
  amount('Price', false),
  category('Category', true);

  const SortOption(this.label, this.defaultAscending);

  /// Display label for the sort option.
  final String label;

  /// Whether ascending is the natural default for this sort type.
  final bool defaultAscending;
}
