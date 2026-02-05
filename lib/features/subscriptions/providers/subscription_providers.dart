import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/core/storage/hive_storage_service.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';
import 'package:uuid/uuid.dart';

part 'subscription_providers.g.dart';

const _uuid = Uuid();

Box<Subscription> get _box => HiveStorageService.subscriptionsBox;

/// Main provider that holds the list of all subscriptions.
/// This is the single source of truth - all other providers derive from this.
@Riverpod(keepAlive: true)
class SubscriptionsNotifier extends _$SubscriptionsNotifier {
  @override
  List<Subscription> build() {
    final data = _loadFromStorage();
    // ignore: avoid_print
    print(
        'SubscriptionsNotifier: Loaded ${data.length} subscriptions from storage');
    return data;
  }

  List<Subscription> _loadFromStorage() {
    final list = _box.values.toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return list;
  }

  void create({
    required String name,
    String? description,
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required SubscriptionCategory category,
    required DateTime startDate,
    String? url,
  }) {
    final subscription = Subscription(
      id: _uuid.v4(),
      name: name,
      description: description,
      amount: amount,
      currency: currency,
      billingCycle: billingCycle,
      category: category,
      startDate: startDate,
      nextBillingDate: billingCycle.nextBillingDate(startDate),
      url: url,
    );

    _box.put(subscription.id, subscription);
    state = _loadFromStorage();
  }

  void update(Subscription subscription) {
    _box.put(subscription.id, subscription);
    state = _loadFromStorage();
  }

  void delete(String id) {
    _box.delete(id);
    state = _loadFromStorage();
  }

  void toggleActive(String id) {
    final sub = _box.get(id);
    if (sub != null) {
      final updated = sub.copyWith(isActive: !sub.isActive);
      _box.put(id, updated);
      state = _loadFromStorage();
    }
  }
}

@riverpod
List<Subscription> subscriptionsList(SubscriptionsListRef ref) {
  final all = ref.watch(subscriptionsNotifierProvider);
  return all.where((s) => s.isActive).toList();
}

@riverpod
double monthlyTotal(MonthlyTotalRef ref) {
  final active = ref.watch(subscriptionsListProvider);
  return active.fold(0, (sum, sub) => sum + sub.monthlyAmount);
}

@riverpod
double yearlyTotal(YearlyTotalRef ref) {
  final active = ref.watch(subscriptionsListProvider);
  return active.fold(0, (sum, sub) => sum + sub.yearlyAmount);
}

@riverpod
List<Subscription> dueSoonSubscriptions(DueSoonSubscriptionsRef ref) {
  final active = ref.watch(subscriptionsListProvider);
  return active.where((sub) => sub.isDueSoon).toList();
}

@riverpod
Subscription? subscriptionById(SubscriptionByIdRef ref, String id) {
  final all = ref.watch(subscriptionsNotifierProvider);
  try {
    return all.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}
