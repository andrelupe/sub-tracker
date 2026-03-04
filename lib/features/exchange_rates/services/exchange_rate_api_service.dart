import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/exchange_rates/models/exchange_rate.dart';

class ExchangeRateApiService {
  final ApiService _apiService;

  const ExchangeRateApiService(this._apiService);

  /// Fetches the latest exchange rates for the given [baseCurrency].
  Future<ExchangeRate> getRates({String baseCurrency = 'EUR'}) async {
    return _apiService.get(
      '/exchange-rates?base=$baseCurrency',
      fromJson: ExchangeRate.fromJson,
    );
  }
}
