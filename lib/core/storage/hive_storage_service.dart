import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

/// Service responsible for initializing and managing Hive storage.
class HiveStorageService {
  static const String _subscriptionsBoxName = 'subscriptions';

  static bool _initialized = false;

  /// Initializes Hive and registers all adapters.
  /// Should be called once at app startup.
  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register adapters
    Hive
      ..registerAdapter(SubscriptionAdapter())
      ..registerAdapter(BillingCycleAdapter())
      ..registerAdapter(SubscriptionCategoryAdapter());

    // Open boxes
    await Hive.openBox<Subscription>(_subscriptionsBoxName);

    _initialized = true;
    debugPrint('HiveStorageService: Initialized successfully');
  }

  /// Returns the subscriptions box.
  static Box<Subscription> get subscriptionsBox {
    if (!_initialized) {
      throw StateError(
        'HiveStorageService not initialized. Call initialize() first.',
      );
    }
    return Hive.box<Subscription>(_subscriptionsBoxName);
  }

  /// Closes all Hive boxes.
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }

  /// Clears all data (useful for testing or reset functionality).
  static Future<void> clearAll() async {
    await subscriptionsBox.clear();
  }
}
