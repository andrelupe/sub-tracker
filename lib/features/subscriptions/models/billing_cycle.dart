import 'package:subtracker/core/extensions/datetime_extensions.dart';

enum BillingCycle {
  weekly('Weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly'),
  biannual('Biannual');

  const BillingCycle(this.label);

  final String label;

  DateTime nextBillingDate(DateTime from) {
    final now = DateTime.now();
    var next = from;

    while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      next = switch (this) {
        BillingCycle.weekly => next.add(const Duration(days: 7)),
        BillingCycle.monthly => next.addMonths(1),
        BillingCycle.quarterly => next.addMonths(3),
        BillingCycle.yearly => next.addYears(1),
        BillingCycle.biannual => next.addMonths(6),
      };
    }

    return next;
  }

  double monthlyEquivalent(double amount) {
    return switch (this) {
      BillingCycle.weekly => amount * 4.33,
      BillingCycle.monthly => amount,
      BillingCycle.quarterly => amount / 3,
      BillingCycle.yearly => amount / 12,
      BillingCycle.biannual => amount / 6,
    };
  }

  double yearlyEquivalent(double amount) {
    return switch (this) {
      BillingCycle.weekly => amount * 52,
      BillingCycle.monthly => amount * 12,
      BillingCycle.quarterly => amount * 4,
      BillingCycle.yearly => amount,
      BillingCycle.biannual => amount * 2,
    };
  }

  /// Values sorted by billing frequency (ascending) for display in dropdowns.
  static const List<BillingCycle> sortedByFrequency = [
    weekly,
    monthly,
    quarterly,
    biannual,
    yearly,
  ];

  static BillingCycle fromJson(int index) {
    return BillingCycle.values[index];
  }

  int toJson() => index;
}
