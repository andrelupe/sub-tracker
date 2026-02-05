import 'package:hive/hive.dart';
import 'package:subtracker/core/extensions/datetime_extensions.dart';

part 'billing_cycle.g.dart';

@HiveType(typeId: 1)
enum BillingCycle {
  @HiveField(0)
  weekly('Weekly'),
  @HiveField(1)
  monthly('Monthly'),
  @HiveField(2)
  quarterly('Quarterly'),
  @HiveField(3)
  yearly('Yearly');

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
    };
  }

  double yearlyEquivalent(double amount) {
    return switch (this) {
      BillingCycle.weekly => amount * 52,
      BillingCycle.monthly => amount * 12,
      BillingCycle.quarterly => amount * 4,
      BillingCycle.yearly => amount,
    };
  }
}
