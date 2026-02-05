import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

void main() {
  group('Subscription', () {
    late Subscription subscription;

    setUp(() {
      subscription = Subscription(
        id: 'test-id',
        name: 'Netflix',
        amount: 15.99,
        currency: 'EUR',
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        startDate: DateTime(2024, 1, 15),
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
      );
    });

    test('monthlyAmount returns correct value for monthly cycle', () {
      expect(subscription.monthlyAmount, equals(15.99));
    });

    test('monthlyAmount returns correct value for yearly cycle', () {
      final yearlySub = subscription.copyWith(
        billingCycle: BillingCycle.yearly,
        amount: 120,
      );

      expect(yearlySub.monthlyAmount, equals(10.0));
    });

    test('yearlyAmount returns correct value for monthly cycle', () {
      expect(subscription.yearlyAmount, closeTo(191.88, 0.01));
    });

    test('isDueSoon returns true when within 7 days', () {
      expect(subscription.isDueSoon, isTrue);
    });

    test('isDueSoon returns false when more than 7 days away', () {
      final futureSub = subscription.copyWith(
        nextBillingDate: DateTime.now().add(const Duration(days: 10)),
      );

      expect(futureSub.isDueSoon, isFalse);
    });

    test('isDueSoon returns false when inactive', () {
      final inactiveSub = subscription.copyWith(isActive: false);

      expect(inactiveSub.isDueSoon, isFalse);
    });
  });

  group('BillingCycle', () {
    test('monthlyEquivalent calculates correctly for weekly', () {
      expect(
        BillingCycle.weekly.monthlyEquivalent(10),
        closeTo(43.3, 0.1),
      );
    });

    test('monthlyEquivalent calculates correctly for quarterly', () {
      expect(
        BillingCycle.quarterly.monthlyEquivalent(30),
        equals(10.0),
      );
    });

    test('yearlyEquivalent calculates correctly for monthly', () {
      expect(
        BillingCycle.monthly.yearlyEquivalent(10),
        equals(120.0),
      );
    });

    test('nextBillingDate returns future date', () {
      final startDate = DateTime(2024, 1, 1);
      final nextDate = BillingCycle.monthly.nextBillingDate(startDate);

      expect(nextDate.isAfter(DateTime.now()), isTrue);
    });
  });
}
