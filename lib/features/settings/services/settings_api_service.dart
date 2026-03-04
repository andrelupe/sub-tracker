import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';

class SettingsApiService {
  final ApiService _apiService;

  const SettingsApiService(this._apiService);

  /// Fetches the current user settings from the API.
  Future<UserSettings> getSettings() async {
    return _apiService.get(
      '/settings',
      fromJson: UserSettings.fromJson,
    );
  }

  /// Updates the base currency in the API.
  Future<void> updateBaseCurrency(String currency) async {
    await _apiService.put('/settings', {
      'baseCurrency': currency,
    });
  }
}
