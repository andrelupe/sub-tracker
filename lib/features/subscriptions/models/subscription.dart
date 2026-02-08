import 'package:subtracker/core/extensions/datetime_extensions.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

class Subscription {
  const Subscription({
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
    this.reminderDaysBefore = 2,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final SubscriptionCategory category;
  final DateTime startDate;
  final DateTime nextBillingDate;
  final bool isActive;
  final String? url;
  final int reminderDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get monthlyAmount => billingCycle.monthlyEquivalent(amount);
  double get yearlyAmount => billingCycle.yearlyEquivalent(amount);
  int get daysUntilNextBilling => nextBillingDate.daysFromNow;
  bool get isDueSoon => isActive && daysUntilNextBilling <= reminderDaysBefore;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      billingCycle: BillingCycle.fromJson(json['billingCycle'] as int),
      category: SubscriptionCategory.fromJson(json['category'] as int),
      startDate: DateTime.parse(json['startDate'] as String),
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      isActive: json['isActive'] as bool,
      url: json['url'] as String?,
      reminderDaysBefore: json['reminderDaysBefore'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'billingCycle': billingCycle.toJson(),
      'category': category.toJson(),
      'startDate': startDate.toIso8601String(),
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'isActive': isActive,
      'url': url,
      'reminderDaysBefore': reminderDaysBefore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

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
    int? reminderDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
