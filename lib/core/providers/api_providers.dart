import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/constants/app_constants.dart';
import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/auth/services/token_storage_service.dart';
import 'package:subtracker/features/subscriptions/services/subscription_api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.read(tokenStorageServiceProvider);

  return ApiService(
    baseUrl: AppConstants.apiBaseUrl,
    getToken: storage.getAccessToken,
    refreshToken: () async {
      try {
        await ref.read(authNotifierProvider.notifier).refreshToken();
        return true;
      } catch (_) {
        return false;
      }
    },
    onAuthFailure: () async {
      await ref.read(authNotifierProvider.notifier).logout();
    },
  );
});

final subscriptionApiServiceProvider = Provider<SubscriptionApiService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return SubscriptionApiService(apiService);
});
