import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

/// Spending total for a single subscription category.
class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.monthlyAmount,
  });

  final SubscriptionCategory category;
  final double monthlyAmount;
}

/// Total spending for a single month.
class MonthlySpending {
  const MonthlySpending({
    required this.month,
    required this.amount,
  });

  final DateTime month;
  final double amount;
}

/// Aggregated analytics statistics.
class AnalyticsStats {
  const AnalyticsStats({
    required this.activeCount,
    required this.inactiveCount,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.avgPerSubscription,
    required this.topCategory,
    required this.mostExpensiveSubscription,
    required this.mostExpensiveAmount,
    required this.nextDue,
    required this.baseCurrency,
  });

  final int activeCount;
  final int inactiveCount;
  final double monthlyTotal;
  final double yearlyTotal;
  final double avgPerSubscription;
  final CategorySpending? topCategory;
  final Subscription? mostExpensiveSubscription;
  final double mostExpensiveAmount;
  final Subscription? nextDue;
  final String baseCurrency;
}
