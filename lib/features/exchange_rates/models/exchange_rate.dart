/// Exchange rate response from the API.
///
/// Represents rates for a given base currency, e.g.:
/// `{ "base": "EUR", "date": "2026-03-03", "rates": { "USD": 1.08, "GBP": 0.86 } }`
class ExchangeRate {
  const ExchangeRate({
    required this.baseCurrency,
    required this.date,
    required this.rates,
  });

  final String baseCurrency;
  final String date;
  final Map<String, double> rates;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'] as Map<String, dynamic>;
    final rates = rawRates.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ExchangeRate(
      baseCurrency: json['base'] as String,
      date: json['date'] as String,
      rates: rates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base': baseCurrency,
      'date': date,
      'rates': rates,
    };
  }
}
