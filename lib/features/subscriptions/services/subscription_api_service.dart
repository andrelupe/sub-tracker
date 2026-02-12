import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

class SubscriptionApiService {
  final ApiService _apiService;

  const SubscriptionApiService(this._apiService);

  Future<List<Subscription>> getAllSubscriptions() async {
    return _apiService.getList(
      '/subscriptions',
      (json) => Subscription.fromJson(json),
    );
  }

  Future<Subscription> getSubscriptionById(String id) async {
    return _apiService.get(
      '/subscriptions/$id',
      fromJson: (json) => Subscription.fromJson(json),
    );
  }

  Future<String> createSubscription({
    required String name,
    String? description,
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required SubscriptionCategory category,
    required DateTime startDate,
    String? url,
    int reminderDaysBefore = 2,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/subscriptions',
      {
        'name': name,
        'description': description,
        'amount': amount,
        'currency': currency,
        'billingCycle': billingCycle.index,
        'category': category.index,
        'startDate': startDate.toIso8601String(),
        'url': url,
        'reminderDaysBefore': reminderDaysBefore,
      },
    );

    return response['id'] as String;
  }

  Future<void> updateSubscription({
    required String id,
    required String name,
    String? description,
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required SubscriptionCategory category,
    required DateTime startDate,
    String? url,
    int reminderDaysBefore = 2,
    bool isActive = true,
  }) async {
    await _apiService.put(
      '/subscriptions/$id',
      {
        'name': name,
        'description': description,
        'amount': amount,
        'currency': currency,
        'billingCycle': billingCycle.index,
        'category': category.index,
        'startDate': startDate.toIso8601String(),
        'url': url,
        'reminderDaysBefore': reminderDaysBefore,
        'isActive': isActive,
      },
    );
  }

  Future<void> deleteSubscription(String id) async {
    await _apiService.delete('/subscriptions/$id');
  }

  Future<void> importSubscriptions(
    List<Map<String, dynamic>> subscriptions,
  ) async {
    await _apiService.postList('/subscriptions/import', subscriptions);
  }

  Future<void> toggleSubscriptionStatus(String id, bool isActive) async {
    final subscription = await getSubscriptionById(id);

    await updateSubscription(
      id: id,
      name: subscription.name,
      description: subscription.description,
      amount: subscription.amount,
      currency: subscription.currency,
      billingCycle: subscription.billingCycle,
      category: subscription.category,
      startDate: subscription.startDate,
      url: subscription.url,
      reminderDaysBefore: subscription.reminderDaysBefore,
      isActive: isActive,
    );
  }
}
