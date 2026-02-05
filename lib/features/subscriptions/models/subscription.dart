import 'package:hive/hive.dart';
import 'package:subtracker/core/extensions/datetime_extensions.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

part 'subscription.g.dart';

@HiveType(typeId: 0)
class Subscription extends HiveObject {
  Subscription({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    this.currency = 'EUR',
    required this.billingCycle,
    required this.category,
    required this.startDate,
    required this.nextBillingDate,
    this.isActive = true,
    this.url,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  final BillingCycle billingCycle;

  @HiveField(6)
  final SubscriptionCategory category;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final DateTime nextBillingDate;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final String? url;

  double get monthlyAmount => billingCycle.monthlyEquivalent(amount);
  double get yearlyAmount => billingCycle.yearlyEquivalent(amount);
  int get daysUntilNextBilling => nextBillingDate.daysFromNow;
  bool get isDueSoon => isActive && daysUntilNextBilling <= 7;

  Subscription copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    String? currency,
    BillingCycle? billingCycle,
    SubscriptionCategory? category,
    DateTime? startDate,
    DateTime? nextBillingDate,
    bool? isActive,
    String? url,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isActive: isActive ?? this.isActive,
      url: url ?? this.url,
    );
  }
}
