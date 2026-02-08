import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/subscriptions/services/subscription_api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final subscriptionApiServiceProvider = Provider<SubscriptionApiService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return SubscriptionApiService(apiService);
});
