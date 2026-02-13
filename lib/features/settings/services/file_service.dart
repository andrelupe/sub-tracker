import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';

// ignore: always_use_package_imports
import 'file_service_stub.dart'
    // ignore: always_use_package_imports
    if (dart.library.html) 'file_service_web.dart' as platform;

/// Service for handling file export and import operations.
class FileService {
  const FileService();

  /// Exports subscriptions as a formatted JSON string.
  String formatExportJson(List<Subscription> subscriptions) {
    final exportData = subscriptions.map((sub) {
      return {
        'name': sub.name,
        'description': sub.description,
        'amount': sub.amount,
        'currency': sub.currency,
        'billingCycle': sub.billingCycle.label,
        'category': sub.category.label,
        'startDate': sub.startDate.toIso8601String().split('T').first,
        'url': sub.url,
        'reminderDaysBefore': sub.reminderDaysBefore,
        'isActive': sub.isActive,
      };
    }).toList();

    // Wrap in subscriptions object
    final wrappedData = {'subscriptions': exportData};

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(wrappedData);
  }

  /// Generates the export filename with current date.
  String get exportFilename {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'subtracker_export_$date.json';
  }

  /// Downloads a JSON file in the browser (web only).
  void downloadJsonWeb(String jsonContent, String filename) {
    if (kIsWeb) {
      platform.downloadFile(jsonContent, filename);
    }
  }

  /// Validates that the JSON content has a 'subscriptions' property with an array.
  List<Map<String, dynamic>>? validateImportJson(String jsonContent) {
    try {
      final dynamic decoded = json.decode(jsonContent);

      // Expect object format: {"subscriptions": [...]}
      if (decoded is! Map<String, dynamic>) return null;
      if (!decoded.containsKey('subscriptions')) return null;
      if (decoded['subscriptions'] is! List) return null;

      final subscriptionsList = decoded['subscriptions'] as List<dynamic>;

      final items = <Map<String, dynamic>>[];
      for (final dynamic item in subscriptionsList) {
        if (item is! Map<String, dynamic>) return null;
        if (!item.containsKey('name') || !item.containsKey('amount')) {
          return null;
        }
        items.add(item);
      }

      return items;
    } catch (_) {
      return null;
    }
  }
}
